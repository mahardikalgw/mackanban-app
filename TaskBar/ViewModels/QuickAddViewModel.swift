//
//  QuickAddViewModel.swift
//  TaskBar
//
//  Backs the ⌘+Shift+N quick-add popup. Title + description only.
//

import Foundation
import Observation

@Observable
final class QuickAddViewModel {
    var title: String = ""
    var itemDescription: String = ""

    /// Defaults for new items.
    var priority: Priority = .medium
    var project: Project?
    var assignees: [TeamMember] = []

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let repository: WorkItemRepository

    init(
        repository: WorkItemRepository,
        defaultProject: Project? = nil
    ) {
        self.repository = repository
        self.project = defaultProject
    }

    @discardableResult
    func save() throws -> WorkItem {
        try repository.create(
            title: title,
            itemDescription: itemDescription,
            status: .todo,
            priority: priority,
            project: project,
            assignees: assignees
        )
    }

    func reset() {
        title = ""
        itemDescription = ""
    }
}
