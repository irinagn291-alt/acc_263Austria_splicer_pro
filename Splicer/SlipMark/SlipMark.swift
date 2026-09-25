import Foundation

/// A miss on the gate. The stub stays seated. Ash does not list these as finished watches.
struct SlipMark: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var stubID: UUID
    var title: String
    var day: Int

    init(id: UUID = UUID(), stubID: UUID, title: String, day: Int) {
        self.id = id
        self.stubID = stubID
        self.title = title
        self.day = day
    }
}
