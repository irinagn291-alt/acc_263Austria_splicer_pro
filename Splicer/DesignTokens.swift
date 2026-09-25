import SwiftUI

/// Named colours live in Assets.xcassets. Hex stays here so the palette has one accessor.
enum DesignTokens {
    /// #284845 void
    static let bg = Color("splBackground")
    /// #385754 lifted panel
    static let surface = Color("splSurface")
    /// #F4F6F6
    static let ink = Color("splInk")
    /// #6DE3D9 primary fill
    static let accent = Color("splAccent")
    /// #B6C3C2 secondary text
    static let muted = Color("splMuted")
}
