import Foundation

/// Lane fold over stubs: Dark, Empty, Piled, or Gated.
/// Stash, Draw, and Burn are the only writers. Rate touches a BurnMark, never the lanes.
struct BoardFold: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case dark
        case empty
        case piled
        case gated
    }

    enum DrawResult: Equatable, Sendable {
        case seated(Stub)
        case bare
        case refusedWhileGated
    }

    enum BurnResult: Equatable, Sendable {
        case marked(BurnMark)
        case refusedWhilePiled
        case refusedWhileDark
    }

    var stack: [Stub]
    var gate: Stub?
    var burnMarks: [BurnMark]
    var slipMarks: [SlipMark]

    init(
        stack: [Stub] = [],
        gate: Stub? = nil,
        burnMarks: [BurnMark] = [],
        slipMarks: [SlipMark] = []
    ) {
        self.stack = stack
        self.gate = gate
        self.burnMarks = burnMarks
        self.slipMarks = slipMarks
    }

    /// Top of the stack is the first element.
    var phase: Phase {
        if gate != nil { return .gated }
        if !stack.isEmpty { return .piled }
        if burnMarks.isEmpty && slipMarks.isEmpty { return .dark }
        return .empty
    }

    mutating func stash(_ stub: Stub) {
        stack.append(stub)
    }

    mutating func draw() -> DrawResult {
        if gate != nil { return .refusedWhileGated }
        guard !stack.isEmpty else { return .bare }
        let top = stack.removeFirst()
        gate = top
        return .seated(top)
    }

    mutating func burn(on date: Date, calendar: Calendar = .current) -> BurnResult {
        switch phase {
        case .piled:
            return .refusedWhilePiled
        case .dark, .empty:
            return .refusedWhileDark
        case .gated:
            guard let seated = gate else { return .refusedWhileDark }
            let mark = BurnMark(
                stubID: seated.id,
                title: seated.title,
                day: BurnMark.dayStamp(for: date, calendar: calendar)
            )
            burnMarks.append(mark)
            gate = nil
            return .marked(mark)
        }
    }

    /// Miss keeps the gate stub and appends a slip. Refused when nothing is seated.
    mutating func slip(on date: Date, calendar: Calendar = .current) -> SlipMark? {
        guard let seated = gate else { return nil }
        let mark = SlipMark(
            stubID: seated.id,
            title: seated.title,
            day: BurnMark.dayStamp(for: date, calendar: calendar)
        )
        slipMarks.append(mark)
        return mark
    }

    /// Grades fold only onto an existing burn. Out of range and unknown ids do nothing.
    mutating func grade(burnID: UUID, stars: Int) -> Bool {
        guard let grade = SpliceGrade(stars: stars) else { return false }
        guard let index = burnMarks.firstIndex(where: { $0.id == burnID }) else { return false }
        burnMarks[index].grade = grade
        return true
    }
}

extension Notification.Name {
    /// Posted after a successful stash, draw, or burn so sheets can reload.
    static let laneFoldNotice = Notification.Name("LaneFoldNotice")
}
