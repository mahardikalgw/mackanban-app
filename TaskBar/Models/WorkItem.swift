//
//  WorkItem.swift
//  TaskBar
//
//  A single task. Backed by SwiftData. Flat (no hierarchy) — the
//  revamp drops epic/story/task nesting in favor of a simple list of
//  tasks per project. Many-to-many with TeamMember for assignees.
//

import Foundation
import SwiftData

@Model
final class WorkItem {
    @Attribute(.unique) var id: UUID

    var title: String
    var itemDescription: String
    var statusRaw: String
    var priorityRaw: String
    var createdAt: Date
    var updatedAt: Date
    var dueDate: Date?
    private var tagsJoined: String

    /// Project this work item belongs to. Optional for safety.
    var project: Project?

    /// People assigned to this task.
    @Relationship(deleteRule: .nullify)
    var assignees: [TeamMember] = []

    init(
        id: UUID = UUID(),
        title: String,
        itemDescription: String = "",
        status: TaskStatus = .todo,
        priority: Priority = .medium,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        dueDate: Date? = nil,
        tags: [String] = [],
        project: Project? = nil,
        assignees: [TeamMember] = []
    ) {
        self.id = id
        self.title = title
        self.itemDescription = itemDescription
        self.statusRaw = status.rawValue
        self.priorityRaw = priority.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dueDate = dueDate
        self.tagsJoined = tags.joined(separator: ",")
        self.project = project
        self.assignees = assignees
    }
}

// MARK: - Typed accessors

extension WorkItem {
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .todo }
        set {
            statusRaw = newValue.rawValue
            updatedAt = .now
        }
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set {
            priorityRaw = newValue.rawValue
            updatedAt = .now
        }
    }

    var tags: [String] {
        tagsJoined
            .split(separator: ",", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func setTags(_ newTags: [String]) {
        tagsJoined = newTags
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: ",")
        updatedAt = .now
    }
}
