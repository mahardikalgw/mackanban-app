//
//  TaskEditorViewModel.swift
//  TaskBar
//
//  Drives the full editor for a work item.
//

import Foundation
import Observation

@Observable
final class TaskEditorViewModel {
    let existing: WorkItem?

    var title: String
    var itemDescription: String
    var priority: Priority
    var dueDate: Date?
    var tagsText: String
    var assignees: [TeamMember]

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let repository: WorkItemRepository
    private(set) var lastError: Error?

    init(item: WorkItem?, repository: WorkItemRepository) {
        self.existing = item
        self.repository = repository
        self.title = item?.title ?? ""
        self.itemDescription = item?.itemDescription ?? ""
        self.priority = item?.priority ?? .medium
        self.dueDate = item?.dueDate
        self.tagsText = (item?.tags ?? []).joined(separator: ", ")
        self.assignees = item?.assignees ?? []
    }

    @discardableResult
    func save() throws -> WorkItem {
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if let existing {
            try repository.update(id: existing.id) { item in
                item.title = self.title.trimmingCharacters(in: .whitespacesAndNewlines)
                item.itemDescription = self.itemDescription
                item.priority = self.priority
                item.dueDate = self.dueDate
                item.setTags(tags)
            }
            try repository.setAssignees(self.assignees, on: existing.id)
            return existing
        } else {
            return try repository.create(
                title: title,
                itemDescription: itemDescription,
                priority: priority,
                dueDate: dueDate,
                tags: tags,
                assignees: assignees
            )
        }
    }
}
