//
//  TeamMember.swift
//  TaskBar
//
//  A person who can be assigned to a WorkItem. Backed by SwiftData so
//  members persist across launches and can be re-used across projects
//  and tasks. Many-to-many with WorkItem via `WorkItem.assignees`.
//
//  Color and initials are deterministic from the name when not
//  explicitly set, so the same person renders the same avatar every
//  time without requiring a design tool.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class TeamMember {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Stored so the avatar doesn't change if the user renames a
    /// display name. Derived from `name` on first creation.
    var initials: String
    /// Stored hex (e.g. "#D49A6A"). Derived from `name` on first creation.
    var colorHex: String
    /// Optional free-form role (e.g. "Designer", "Engineer").
    var role: String?
    var createdAt: Date

    /// Inverse of `WorkItem.assignees`.
    @Relationship(deleteRule: .nullify, inverse: \WorkItem.assignees)
    var assignedItems: [WorkItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        initials: String? = nil,
        colorHex: String? = nil,
        role: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.initials = initials ?? TeamMember.deriveInitials(from: name)
        self.colorHex = colorHex ?? TeamMember.deriveColorHex(from: name)
        self.role = role
        self.createdAt = createdAt
    }
}

// MARK: - Display

extension TeamMember {
    var color: Color { Color(hex: colorHex) ?? .accentColor }

    /// Display-friendly name (trimmed, original case preserved).
    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Stable initials suitable for the avatar circle. Capped at 2 chars.
    static func deriveInitials(from name: String) -> String {
        let parts = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ", omittingEmptySubsequences: true)
        let chars: [Character] = parts.prefix(2).compactMap { $0.first }
        if !chars.isEmpty { return String(chars).uppercased() }
        // Fallback: first letter of the raw string, or "?" if empty.
        return String(name.first ?? "?").uppercased()
    }

    /// Deterministic warm-palette color derived from a stable hash of the name.
    /// Uses a curated set of warm tones that sit well on the beige light bg.
    static func deriveColorHex(from name: String) -> String {
        let palette: [String] = [
            "#D49A6A", // warm tan
            "#C2845A", // soft brown
            "#8E5A3C", // cocoa
            "#A86A4A", // terracotta
            "#7E8F6A", // sage
            "#5A7A8C", // dusty blue
            "#A28F6E", // sand
            "#8C6A8E"  // muted plum
        ]
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return palette[0] }
        // FNV-1a 32-bit hash.
        var hash: UInt32 = 0x811c9dc5
        for byte in trimmed.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 0x01000193
        }
        return palette[Int(hash % UInt32(palette.count))]
    }
}
