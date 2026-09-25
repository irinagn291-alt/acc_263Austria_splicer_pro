import Foundation

/// A title card on the board. Stash writes one onto Stack. Draw may seat it on Gate.
struct Stub: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var title: String
    var catalogueCode: String?

    init(id: UUID = UUID(), title: String, catalogueCode: String? = nil) {
        self.id = id
        self.title = title
        self.catalogueCode = catalogueCode
    }
}

/// Grade fused only onto a BurnMark. One through five.
struct SpliceGrade: Codable, Equatable, Sendable {
    var stars: Int

    init?(stars: Int) {
        guard (1...5).contains(stars) else { return nil }
        self.stars = stars
    }
}
