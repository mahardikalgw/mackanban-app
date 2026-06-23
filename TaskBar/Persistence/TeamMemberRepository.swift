//
//  TeamMemberRepository.swift
//  TaskBar
//
//  CRUD for the TeamMember entity. Used by the seed step and by
//  the future Team management view.
//

import Foundation
import SwiftData

enum TeamMemberRepositoryError: Error, Equatable {
    case notFound(UUID)
    case invalidName
}

final class TeamMemberRepository: @unchecked Sendable {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create

    @discardableResult
    func create(
        name: String,
        role: String? = nil
    ) throws -> TeamMember {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TeamMemberRepositoryError.invalidName }
        let member = TeamMember(name: trimmed, role: role)
        context.insert(member)
        try context.save()
        return member
    }

    // MARK: - Read

    func fetchAll() throws -> [TeamMember] {
        let descriptor = FetchDescriptor<TeamMember>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func find(id: UUID) throws -> TeamMember? {
        var descriptor = FetchDescriptor<TeamMember>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: - Update

    func update(id: UUID, _ mutate: (TeamMember) throws -> Void) throws {
        guard let member = try find(id: id) else { throw TeamMemberRepositoryError.notFound(id) }
        try mutate(member)
        try context.save()
    }

    // MARK: - Delete

    func delete(id: UUID) throws {
        guard let member = try find(id: id) else { throw TeamMemberRepositoryError.notFound(id) }
        context.delete(member)
        try context.save()
    }
}
