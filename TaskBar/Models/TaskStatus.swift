//
//  TaskStatus.swift
//  TaskBar
//
//  Four-column Kanban status. Notion-style muted accent colors.
//

import Foundation
import SwiftUI

enum TaskStatus: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case todo
    case doing
    case review
    case done

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .todo: "To Do"
        case .doing: "In Progress"
        case .review: "Review"
        case .done: "Done"
        }
    }

    var headerLabel: String {
        switch self {
        case .todo: "TO DO"
        case .doing: "IN PROGRESS"
        case .review: "REVIEW"
        case .done: "DONE"
        }
    }

    var searchKey: String { displayName.lowercased() }

    var aliasKeys: [String] {
        switch self {
        case .doing: ["doing", "in progress", "wip"]
        case .review: ["review", "reviewing", "qa"]
        default: []
        }
    }

    /// SF Symbol shown next to the status dot in the column header.
    var iconName: String {
        switch self {
        case .todo: "circle"
        case .doing: "half.circle"
        case .review: "eye"
        case .done: "checkmark.circle.fill"
        }
    }

    /// Muted dot color used in the column header & card meta.
    var dotColor: Color {
        switch self {
        case .todo:   Color(red: 0.47, green: 0.47, blue: 0.45)   // #787774 gray
        case .doing:  Color(red: 0.76, green: 0.57, blue: 0.26)   // #C29243 amber
        case .review: Color(red: 0.28, green: 0.49, blue: 0.65)   // #487CA5 blue
        case .done:   Color(red: 0.33, green: 0.56, blue: 0.38)   // #548164 green
        }
    }

    /// Header color (kept for the drop-target highlight ring).
    var headerColor: Color { dotColor }
}
