//
//  WorkItemRepository.swift
//  TaskBar
//
//  CRUD + filtering for the WorkItem entity. Flat (no hierarchy).
//

import Foundation
import SwiftData

enum WorkItemRepositoryError: Error, Equatable {
    case notFound(UUID)
    case invalidTitle
}

final class WorkItemRepository: @unchecked Sendable {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create

    @discardableResult
    func create(
        title: String,
        itemDescription: String = "",
        status: TaskStatus = .todo,
        priority: Priority = .medium,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        dueDate: Date? = nil,
        tags: [String] = [],
        project: Project? = nil
    ) throws -> WorkItem {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WorkItemRepositoryError.invalidTitle }
        let item = WorkItem(
            title: trimmed,
            itemDescription: itemDescription,
            status: status,
            priority: priority,
            createdAt: createdAt,
            updatedAt: updatedAt,
            dueDate: dueDate,
            tags: tags,
            project: project
        )
        context.insert(item)
        try context.save()
        return item
    }

    // MARK: - Read

    func fetchAll() throws -> [WorkItem] {
        let descriptor = FetchDescriptor<WorkItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetch(project: Project) throws -> [WorkItem] {
        let projectID = project.id
        let descriptor = FetchDescriptor<WorkItem>(
            predicate: #Predicate { $0.project?.id == projectID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetch(project: Project, status: TaskStatus) throws -> [WorkItem] {
        let projectID = project.id
        let statusRaw = status.rawValue
        let descriptor = FetchDescriptor<WorkItem>(
            predicate: #Predicate {
                $0.project?.id == projectID && $0.statusRaw == statusRaw
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func find(id: UUID) throws -> WorkItem? {
        var descriptor = FetchDescriptor<WorkItem>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: - Update

    func updateStatus(id: UUID, to newStatus: TaskStatus) throws {
        guard let item = try find(id: id) else { throw WorkItemRepositoryError.notFound(id) }
        guard item.status != newStatus else { return }
        item.status = newStatus
        try context.save()
    }

    func update(id: UUID, _ mutate: (WorkItem) throws -> Void) throws {
        guard let item = try find(id: id) else { throw WorkItemRepositoryError.notFound(id) }
        try mutate(item)
        item.updatedAt = .now
        try context.save()
    }

    // MARK: - Delete

    func delete(id: UUID) throws {
        guard let item = try find(id: id) else { throw WorkItemRepositoryError.notFound(id) }
        context.delete(item)
        try context.save()
    }

    func deleteAll() throws {
        let all = try fetchAll()
        for item in all { context.delete(item) }
        try context.save()
    }
}
