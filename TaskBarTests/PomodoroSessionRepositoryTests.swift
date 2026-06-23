//
//  PomodoroSessionRepositoryTests.swift
//  TaskBarTests
//

import XCTest
import SwiftData
@testable import TaskBar

final class PomoroSessionRepositoryTests: XCTestCase {

    private func makeRepo() throws -> PomodoroSessionRepository {
        let container = try ModelContainerProvider.makeInMemoryContainer()
        let context = ModelContext(container)
        return PomodoroSessionRepository(context: context)
    }

    func testCreatePersistsDefaults() throws {
        let repo = try makeRepo()
        let session = try repo.create(taskID: UUID())
        XCTAssertEqual(session.durationSeconds, 25 * 60)
        XCTAssertNotNil(session.completedAt)
    }

    func testCountByTaskFilters() throws {
        let repo = try makeRepo()
        let taskA = UUID()
        let taskB = UUID()
        try repo.create(taskID: taskA)
        try repo.create(taskID: taskA)
        try repo.create(taskID: taskB)
        XCTAssertEqual(try repo.count(taskID: taskA), 2)
        XCTAssertEqual(try repo.count(taskID: taskB), 1)
        XCTAssertEqual(try repo.count(taskID: UUID()), 0)
    }

    func testDeleteAllRemovesOnlyMatchingSessions() throws {
        let repo = try makeRepo()
        let taskA = UUID()
        let taskB = UUID()
        try repo.create(taskID: taskA)
        try repo.create(taskID: taskA)
        try repo.create(taskID: taskB)
        try repo.deleteAll(for: taskA)
        XCTAssertEqual(try repo.count(taskID: taskA), 0)
        XCTAssertEqual(try repo.count(taskID: taskB), 1)
    }

    func testFetchAllReturnsByCompletedAtDesc() throws {
        let repo = try makeRepo()
        let taskID = UUID()
        try repo.create(taskID: taskID, completedAt: Date(timeIntervalSince1970: 1_000))
        try repo.create(taskID: taskID, completedAt: Date(timeIntervalSince1970: 2_000))
        let all = try repo.fetchAll(for: taskID)
        XCTAssertEqual(all.first?.completedAt, Date(timeIntervalSince1970: 2_000))
    }
}
