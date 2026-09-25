import Foundation

/// One Codable root. The file of record is this value under `spl.lane.v1`.
struct LaneChart: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var stack: [Stub]
    var gate: Stub?
    var burnMarks: [BurnMark]
    var slipMarks: [SlipMark]
    var cachedTitles: [Stub]
    var onboardingComplete: Bool

    static let currentSchema = 1

    init(
        schemaVersion: Int = LaneChart.currentSchema,
        stack: [Stub] = [],
        gate: Stub? = nil,
        burnMarks: [BurnMark] = [],
        slipMarks: [SlipMark] = [],
        cachedTitles: [Stub] = [],
        onboardingComplete: Bool = false
    ) {
        self.schemaVersion = schemaVersion
        self.stack = stack
        self.gate = gate
        self.burnMarks = burnMarks
        self.slipMarks = slipMarks
        self.cachedTitles = cachedTitles
        self.onboardingComplete = onboardingComplete
    }

    var fold: BoardFold {
        BoardFold(stack: stack, gate: gate, burnMarks: burnMarks, slipMarks: slipMarks)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case 1:
            schemaVersion = version
            stack = try container.decodeIfPresent([Stub].self, forKey: .stack) ?? []
            gate = try container.decodeIfPresent(Stub.self, forKey: .gate)
            burnMarks = try container.decodeIfPresent([BurnMark].self, forKey: .burnMarks) ?? []
            slipMarks = try container.decodeIfPresent([SlipMark].self, forKey: .slipMarks) ?? []
            cachedTitles = try container.decodeIfPresent([Stub].self, forKey: .cachedTitles) ?? []
            onboardingComplete = try container.decodeIfPresent(Bool.self, forKey: .onboardingComplete) ?? false
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unknown LaneChart schema \(version)."
            )
        }
    }
}

enum ChartLoad: Equatable, Sendable {
    case restored
    case restoredFromBackup
    case emptyAfterCorruption
}

/// Screen seam. Memory is the source of truth. UserDefaults is a debounced projection.
actor LaneChartStore {
    static let storageKey = "spl.lane.v1"
    static let backupKey = "spl.lane.v1.backup"

    private let defaults: UserDefaults
    private let debounceNanoseconds: UInt64
    private var chart: LaneChart
    private var saveTask: Task<Void, Never>?
    private var saveGeneration = 0
    private(set) var load: ChartLoad
    private(set) var lastWriteFailed = false

    /// Builds a store on a private suite. The suite object never leaves this function.
    static func makeSuite(
        _ suite: String,
        record: Data? = nil,
        backup: Data? = nil,
        debounceNanoseconds: UInt64 = 400_000_000
    ) -> LaneChartStore? {
        guard let defaults = UserDefaults(suiteName: suite) else { return nil }
        defaults.removePersistentDomain(forName: suite)
        if let record {
            defaults.set(record, forKey: storageKey)
        }
        if let backup {
            defaults.set(backup, forKey: backupKey)
        }
        return LaneChartStore(defaults: defaults, debounceNanoseconds: debounceNanoseconds)
    }

    /// Opens a suite that already holds a chart. Does not clear it.
    static func openSuite(_ suite: String, debounceNanoseconds: UInt64 = 400_000_000) -> LaneChartStore? {
        guard let defaults = UserDefaults(suiteName: suite) else { return nil }
        return LaneChartStore(defaults: defaults, debounceNanoseconds: debounceNanoseconds)
    }

    init(defaults: UserDefaults, debounceNanoseconds: UInt64 = 400_000_000) {
        self.defaults = defaults
        self.debounceNanoseconds = debounceNanoseconds
        let loaded = LaneChartStore.read(from: defaults)
        self.chart = loaded.chart
        self.load = loaded.load
    }

    func snapshot() -> LaneChart {
        chart
    }

    func recordIsPresent() -> Bool {
        defaults.data(forKey: Self.storageKey) != nil
    }

    func stash(_ stub: Stub) {
        var fold = chart.fold
        fold.stash(stub)
        apply(fold)
        postNotice()
        scheduleSave()
    }

    func draw() -> BoardFold.DrawResult {
        var fold = chart.fold
        let result = fold.draw()
        if case .seated = result {
            apply(fold)
            postNotice()
            scheduleSave()
        }
        return result
    }

    func burn(on date: Date, calendar: Calendar = .current) -> BoardFold.BurnResult {
        var fold = chart.fold
        let result = fold.burn(on: date, calendar: calendar)
        if case .marked = result {
            apply(fold)
            postNotice()
            scheduleSave()
        }
        return result
    }

    func slip(on date: Date, calendar: Calendar = .current) -> SlipMark? {
        var fold = chart.fold
        let mark = fold.slip(on: date, calendar: calendar)
        if mark != nil {
            apply(fold)
            scheduleSave()
        }
        return mark
    }

    func grade(burnID: UUID, stars: Int) -> Bool {
        var fold = chart.fold
        let applied = fold.grade(burnID: burnID, stars: stars)
        if applied {
            apply(fold)
            scheduleSave()
        }
        return applied
    }

    func remember(_ titles: [Stub]) {
        var seen = Set(chart.cachedTitles.map(\.id))
        for title in titles where seen.insert(title.id).inserted {
            chart.cachedTitles.append(title)
        }
        scheduleSave()
    }

    func markOnboardingComplete() {
        chart.onboardingComplete = true
        scheduleSave()
    }

    func reopenOnboarding() {
        chart.onboardingComplete = false
        scheduleSave()
    }

    func flush() async {
        saveGeneration += 1
        saveTask?.cancel()
        saveTask = nil
        writeNow()
    }

    func resetAllData() async {
        saveGeneration += 1
        saveTask?.cancel()
        saveTask = nil
        chart = LaneChart()
        load = .restored
        lastWriteFailed = false
        defaults.removeObject(forKey: Self.storageKey)
        defaults.removeObject(forKey: Self.backupKey)
    }

    private func apply(_ fold: BoardFold) {
        chart.stack = fold.stack
        chart.gate = fold.gate
        chart.burnMarks = fold.burnMarks
        chart.slipMarks = fold.slipMarks
    }

    private func scheduleSave() {
        saveGeneration += 1
        let ticket = saveGeneration
        saveTask?.cancel()
        let wait = debounceNanoseconds
        saveTask = Task {
            if wait > 0 {
                do {
                    try await Task.sleep(nanoseconds: wait)
                } catch {
                    return
                }
            }
            guard !Task.isCancelled else { return }
            self.commitSave(ticket: ticket)
        }
    }

    private func commitSave(ticket: Int) {
        guard ticket == saveGeneration else { return }
        writeNow()
    }

    private func writeNow() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(chart)
            if let previous = defaults.data(forKey: Self.storageKey) {
                defaults.set(previous, forKey: Self.backupKey)
            }
            defaults.set(data, forKey: Self.storageKey)
            lastWriteFailed = false
        } catch {
            lastWriteFailed = true
        }
    }

    private func postNotice() {
        NotificationCenter.default.post(name: .laneFoldNotice, object: nil)
    }

    private static func read(from defaults: UserDefaults) -> (chart: LaneChart, load: ChartLoad) {
        if let data = defaults.data(forKey: storageKey) {
            if let chart = decode(data) {
                return (chart, .restored)
            }
            if let backup = defaults.data(forKey: backupKey), let chart = decode(backup) {
                return (chart, .restoredFromBackup)
            }
            return (LaneChart(), .emptyAfterCorruption)
        }
        return (LaneChart(), .restored)
    }

    private static func decode(_ data: Data) -> LaneChart? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return try? decoder.decode(LaneChart.self, from: data)
    }
}
