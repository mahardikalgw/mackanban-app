//
//  PomodoroSessionRepository.swift
//  TaskBar
//
//  CRUD for the PomodoroSession entity. Used by the app's
//  `pomodoroWorkSessionCompleted` observer to record completed
//  work sessions, and by future stats views to count them.
//

import Foundation
import SwiftData

final class PomodoroSessionRepository: @unchecked Sendable {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create

    @discardableResult
    func create(
        taskID: UUID,
        completedAt: Date = .now,
        durationSeconds: Int = 25 * 60
    ) throws -> PomodoroSession {
        let session = PomodoroSession(
            taskID: taskID,
            completedAt: completedAt,
            durationSeconds: durationSeconds
        )
        context.insert(session)
        try context.save()
        return session
    }

    // MARK: - Read

    /// Number of completed work sessions logged for the given task.
    func count(taskID: UUID) throws -> Int {
        let descriptor = FetchDescriptor<PomodoroSession>(
            predicate: #Predicate { $0.taskID == taskID }
        )
        return try context.fetchCount(descriptor)
    }

    func fetchAll(for taskID: UUID) throws -> [PomodoroSession] {
        let descriptor = FetchDescriptor<PomodoroSession>(
            predicate: #Predicate { $0.taskID == taskID },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Delete

    func deleteAll(for taskID: UUID) throws {
        let descriptor = FetchDescriptor<PomodoroSession>(
            predicate: #Predicate { $0.taskID == taskID }
        )
        let all = try context.fetch(descriptor)
        for session in all { context.delete(session) }
        try context.save()
    }
}
