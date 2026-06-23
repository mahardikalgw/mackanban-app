//
//  Project.swift
//  TaskBar
//
//  A Project groups related work items (epics / stories / tasks).
//  One project is selected at a time in the popover.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Hex color (e.g. "#5C95FF") used for the sidebar dot + accents.
    var colorHex: String
    var createdAt: Date
    /// Optional short blurb shown under the project name.
    var projectDescription: String

    /// Inverse of `WorkItem.project`.
    @Relationship(deleteRule: .nullify, inverse: \WorkItem.project)
    var workItems: [WorkItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#5C95FF",
        createdAt: Date = .now,
        projectDescription: String = ""
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.projectDescription = projectDescription
    }
}

extension Project {
    /// SwiftUI Color parsed from the stored hex string.
    var color: Color { Color(hex: colorHex) ?? .accentColor }
}

extension Color {
    /// Lenient hex parser — accepts "#RRGGBB", "#RRGGBBAA", "RRGGBB".
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8,
              let v = UInt64(s, radix: 16) else { return nil }
        let r, g, b, a: Double
        if s.count == 6 {
            r = Double((v >> 16) & 0xFF) / 255
            g = Double((v >> 8) & 0xFF) / 255
            b = Double(v & 0xFF) / 255
            a = 1
        } else {
            r = Double((v >> 24) & 0xFF) / 255
            g = Double((v >> 16) & 0xFF) / 255
            b = Double((v >> 8) & 0xFF) / 255
            a = Double(v & 0xFF) / 255
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
