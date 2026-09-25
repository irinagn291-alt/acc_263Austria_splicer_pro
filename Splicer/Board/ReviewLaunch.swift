import Foundation

/// Launch keys read once after onboarding. They are not tabs.
enum ReviewSurface: String, Equatable, Sendable {
    case today
    case log
    case goals
    case discover
    case settings
    case ash
    case profile
    case board
    case onboarding
}

enum ReviewLaunch {
    /// Live launch key. Shots pass `-ReviewScreen` on the process arguments.
    static var screen: ReviewSurface? {
        surface(from: ProcessInfo.processInfo.arguments)
    }

    static func surface(from arguments: [String]) -> ReviewSurface? {
        guard let flag = arguments.firstIndex(of: "-ReviewScreen"),
              arguments.indices.contains(flag + 1)
        else {
            return nil
        }
        return ReviewSurface(rawValue: arguments[flag + 1])
    }
}
