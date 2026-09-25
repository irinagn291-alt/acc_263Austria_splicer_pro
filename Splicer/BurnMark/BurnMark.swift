import Foundation

/// A finished watch. Ash reads these in order. The stub leaves the board when this is written.
struct BurnMark: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var stubID: UUID
    var title: String
    /// Calendar day as YYYYMMDD, from `Calendar.startOfDay`.
    var day: Int
    var grade: SpliceGrade?

    init(id: UUID = UUID(), stubID: UUID, title: String, day: Int, grade: SpliceGrade? = nil) {
        self.id = id
        self.stubID = stubID
        self.title = title
        self.day = day
        self.grade = grade
    }

    static func dayStamp(for date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }
}

/// OLS of seconds against day, plus the five watch positions. COSC holds when |dev| is at most 4 s/day.
/// Computed on read. Nothing derived is stored on the chart.
struct RateDesk: Equatable, Sendable {
    struct Fit: Equatable, Sendable {
        var secondsPerDay: Double
        var rSquared: Double
        var withinCOSC: Bool
    }

    struct Positions: Equatable, Sendable {
        var dialUp: Double
        var dialDown: Double
        var crownUp: Double
        var crownLeft: Double
        var crownDown: Double

        var spread: Double {
            let values = [dialUp, dialDown, crownUp, crownLeft, crownDown]
            guard let high = values.max(), let low = values.min() else { return 0 }
            return high - low
        }
    }

    /// `samples` are (day index, seconds). Needs two distinct days.
    static func fit(samples: [(day: Double, seconds: Double)]) -> Fit? {
        guard samples.count >= 2 else { return nil }
        let count = Double(samples.count)
        let sumX = samples.reduce(0) { $0 + $1.day }
        let sumY = samples.reduce(0) { $0 + $1.seconds }
        let sumXY = samples.reduce(0) { $0 + $1.day * $1.seconds }
        let sumX2 = samples.reduce(0) { $0 + $1.day * $1.day }
        let denominator = count * sumX2 - sumX * sumX
        guard denominator != 0 else { return nil }
        let slope = (count * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / count
        let meanY = sumY / count
        let ssTot = samples.reduce(0) { $0 + ($1.seconds - meanY) * ($1.seconds - meanY) }
        let ssRes = samples.reduce(0) { partial, sample in
            let predicted = intercept + slope * sample.day
            let delta = sample.seconds - predicted
            return partial + delta * delta
        }
        let rSquared = ssTot == 0 ? 1 : 1 - ssRes / ssTot
        return Fit(secondsPerDay: slope, rSquared: rSquared, withinCOSC: abs(slope) <= 4)
    }
}
