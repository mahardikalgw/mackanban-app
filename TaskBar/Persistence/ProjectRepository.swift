//
//  ProjectRepository.swift
//  TaskBar
//
//  CRUD for the Project entity.
//

import Foundation
import SwiftData

enum ProjectRepositoryError: Error, Equatable {
    case notFound(UUID)
    case invalidName
}

final class ProjectRepository: @unchecked Sendable {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create

    @discardableResult
    func create(
        name: String,
        colorHex: String = "#5C95FF",
        projectDescription: String = ""
    ) throws -> Project {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ProjectRepositoryError.invalidName }
        let project = Project(
            name: trimmed,
            colorHex: colorHex,
            projectDescription: projectDescription
        )
        context.insert(project)
        try context.save()
        return project
    }

    // MARK: - Read

    func fetchAll() throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func find(id: UUID) throws -> Project? {
        var descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: - Update

    func update(id: UUID, _ mutate: (Project) throws -> Void) throws {
        guard let project = try find(id: id) else { throw ProjectRepositoryError.notFound(id) }
        try mutate(project)
        try context.save()
    }

    // MARK: - Delete

    func delete(id: UUID) throws {
        guard let project = try find(id: id) else { throw ProjectRepositoryError.notFound(id) }
        context.delete(project)
        try context.save()
    }
}
