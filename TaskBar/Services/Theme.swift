//
//  Theme.swift
//  TaskBar
//
//  Centralised theme system. One `Theme` struct holds every color
//  token; each view reads `@Environment(\.theme)`. `ThemeManager`
//  is an `@Observable` singleton that persists the user's choice
//  to `UserDefaults` and broadcasts changes via NotificationCenter.
//
//  Revamp palette: warm beige + soft white surfaces, with a darker
//  warm-graphite accent. Reads as "premium productivity app".
//

import SwiftUI
import Observation

// MARK: - AppTheme (user-facing choice)

enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light:  "Light"
        case .dark:   "Dark"
        }
    }

    var iconName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light:  "sun.max"
        case .dark:   "moon.fill"
        }
    }

    /// What to pass to `.preferredColorScheme(...)`.
    /// `.system` → nil (let SwiftUI follow the OS).
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}

extension Notification.Name {
    static let themeChanged = Notification.Name("Mackanban.themeChanged")
}

// MARK: - Theme (color tokens)

struct Theme: Sendable {
    let bg: Color                  // window / detail background
    let surfaceSubtle: Color       // sidebar, columns, secondary buttons
    let surfaceHover: Color        // column hover when targeted for drop
    let border: Color              // card / field / button border
    let divider: Color             // horizontal dividers in top bar / sheets
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let accent: Color              // primary action bg / selected row fg
    let accentForeground: Color    // text on accent bg
    let cardBg: Color
    let cardBgHover: Color
    let cardBorder: Color
    let cardBorderHover: Color
    let fieldBg: Color
    let tagBg: Color
    let shadow: Color              // card drop shadow (used at low opacity)

    /// Warm beige + soft white. Premium productivity / Linear-inspired.
    static let light = Theme(
        bg:                 Color(red: 0.980, green: 0.969, blue: 0.949), // #FAF7F2
        surfaceSubtle:      Color(red: 0.949, green: 0.933, blue: 0.906), // #F2EEE7
        surfaceHover:       Color(red: 0.929, green: 0.910, blue: 0.875), // #EDE8DF
        border:             Color(red: 0.910, green: 0.886, blue: 0.843), // #E8E2D7
        divider:            Color(red: 0.910, green: 0.886, blue: 0.843),
        textPrimary:        Color(red: 0.122, green: 0.106, blue: 0.086), // #1F1B16
        textSecondary:      Color(red: 0.420, green: 0.384, blue: 0.345), // #6B6258
        textTertiary:       Color(red: 0.612, green: 0.576, blue: 0.529), // #9C9387
        accent:             Color(red: 0.122, green: 0.106, blue: 0.086), // #1F1B16 warm graphite
        accentForeground:   Color(red: 0.980, green: 0.969, blue: 0.949),
        cardBg:             Color(red: 1.000, green: 1.000, blue: 1.000), // pure white for cards
        cardBgHover:        Color(red: 1.000, green: 0.996, blue: 0.984), // warm white hover
        cardBorder:         Color(red: 0.910, green: 0.886, blue: 0.843),
        cardBorderHover:    Color(red: 0.831, green: 0.804, blue: 0.749),
        fieldBg:            Color(red: 1.000, green: 1.000, blue: 1.000),
        tagBg:              Color(red: 0.949, green: 0.933, blue: 0.906),
        shadow:             Color(red: 0.122, green: 0.106, blue: 0.086)
    )

    /// Warm-graphite dark variant — not pure neutral gray; the bg has
    /// a subtle brown undertone so the warm palette reads consistently.
    static let dark = Theme(
        bg:                 Color(red: 0.110, green: 0.102, blue: 0.094), // #1C1A18
        surfaceSubtle:      Color(red: 0.145, green: 0.133, blue: 0.125), // #252220
        surfaceHover:       Color(red: 0.173, green: 0.161, blue: 0.149), // #2C2926
        border:             Color(red: 0.227, green: 0.212, blue: 0.184), // #3A362F
        divider:            Color(red: 0.227, green: 0.212, blue: 0.184),
        textPrimary:        Color(red: 0.957, green: 0.937, blue: 0.902), // #F4EFE6
        textSecondary:      Color(red: 0.745, green: 0.714, blue: 0.659), // #BEB6A8
        textTertiary:       Color(red: 0.541, green: 0.514, blue: 0.471), // #8A8378
        accent:             Color(red: 0.957, green: 0.937, blue: 0.902), // #F4EFE6
        accentForeground:   Color(red: 0.110, green: 0.102, blue: 0.094),
        cardBg:             Color(red: 0.165, green: 0.153, blue: 0.137), // #2A2723
        cardBgHover:        Color(red: 0.196, green: 0.184, blue: 0.165), // #322F2A
        cardBorder:         Color(red: 0.227, green: 0.212, blue: 0.184),
        cardBorderHover:    Color(red: 0.298, green: 0.275, blue: 0.235),
        fieldBg:            Color(red: 0.165, green: 0.153, blue: 0.137),
        tagBg:              Color(red: 0.196, green: 0.184, blue: 0.165),
        shadow:             .black
    )
}

// MARK: - Environment plumbing

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .light
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - ThemeManager (state + persistence)

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var current: AppTheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: defaultsKey)
            NotificationCenter.default.post(
                name: .themeChanged,
                object: nil,
                userInfo: ["theme": current]
            )
        }
    }

    private let defaultsKey = "appTheme"

    init() {
        if let raw = UserDefaults.standard.string(forKey: defaultsKey),
           let theme = AppTheme(rawValue: raw) {
            self.current = theme
        } else {
            self.current = .system
        }
    }
}
