//
//  Priority.swift
//  TaskBar
//
//  Task priority. Notion-style muted accents — a small dot only,
//  no glow, no neon.
//

import Foundation
import SwiftUI

enum Priority: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    /// Short uppercase label.
    var shortLabel: String {
        switch self {
        case .low: "LOW"
        case .medium: "MED"
        case .high: "HIGH"
        }
    }

    /// Muted dot color used on cards.
    var dotColor: Color {
        switch self {
        case .high:   Color(red: 0.83, green: 0.30, blue: 0.28)   // #D44C47 red
        case .medium: Color(red: 0.80, green: 0.57, blue: 0.18)   // #CB912F amber
        case .low:    Color(red: 0.30, green: 0.58, blue: 0.46)   // #4D9375 green
        }
    }

    /// Backwards-compat alias used in card UI.
    var accentColor: Color { dotColor }
    var softBackground: Color { dotColor.opacity(0.12) }

    /// SF Symbol icon used in the priority pill.
    var iconName: String {
        switch self {
        case .high: "exclamationmark"
        case .medium: "equal"
        case .low: "arrow.down"
        }
    }

    /// Sort weight — higher priority sorts first within a column.
    var sortWeight: Int {
        switch self {
        case .high: 0
        case .medium: 1
        case .low: 2
        }
    }
}
