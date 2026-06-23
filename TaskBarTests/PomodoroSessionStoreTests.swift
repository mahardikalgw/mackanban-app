//
//  PomodoroSessionStoreTests.swift
//  TaskBarTests
//

import XCTest
import SwiftData
@testable import TaskBar

@MainActor
final class PomodoroSessionStoreTests: XCTestCase {

    override func setUp() async throws {
        PomodoroSessionStore.shared.reset()
    }

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainerProvider.makeInMemoryContainer()
        return ModelContext(container)
    }

    func testRefreshAllPopulatesCounts() throws {
        let context = try makeContext()
        let sessionRepo = PomodoroSessionRepository(context: context)
        let workRepo = WorkItemRepository(context: context)
        let projRepo = ProjectRepository(context: context)
        let project = try projRepo.create(name: "Test")

        let itemA = try workRepo.create(title: "A", project: project)
        let itemB = try workRepo.create(title: "B", project: project)
        let unused = try workRepo.create(title: "C", project: project)

        // Record 2 sessions for itemA, 1 for itemB.
        try sessionRepo.create(taskID: itemA.id)
        try sessionRepo.create(taskID: itemA.id)
        try sessionRepo.create(taskID: itemB.id)

        PomodoroSessionStore.shared.attach(context: context)
        PomodoroSessionStore.shared.refreshAll(items: [itemA, itemB, unused])

        XCTAssertEqual(PomodoroSessionStore.shared.count(for: itemA.id), 2)
        XCTAssertEqual(PomodoroSessionStore.shared.count(for: itemB.id), 1)
        XCTAssertEqual(PomodoroSessionStore.shared.count(for: unused.id), 0)
    }

    func testRefreshAllDropsOrphanedKeys() throws {
        let context = try makeContext()
        let workRepo = WorkItemRepository(context: context)
        let projRepo = ProjectRepository(context: context)
        let project = try projRepo.create(name: "Test")

        let item = try workRepo.create(title: "A", project: project)

        PomodoroSessionStore.shared.attach(context: context)
        // Seed a stale key.
        PomodoroSessionStore.shared.refreshAll(items: [item])
        XCTAssertTrue(PomodoroSessionStore.shared.counts.keys.contains(item.id))

        // Refresh with empty items — orphaned key should be dropped.
        PomodoroSessionStore.shared.refreshAll(items: [])
        XCTAssertFalse(PomodoroSessionStore.shared.counts.keys.contains(item.id))
    }

    func testNotificationUpdatesOnlyAffectedTask() throws {
        let context = try makeContext()
        let sessionRepo = PomodoroSessionRepository(context: context)
        let workRepo = WorkItemRepository(context: context)
        let projRepo = ProjectRepository(context: context)
        let project = try projRepo.create(name: "Test")

        let itemA = try workRepo.create(title: "A", project: project)
        let itemB = try workRepo.create(title: "B", project: project)

        PomodoroSessionStore.shared.attach(context: context)
        PomodoroSessionStore.shared.refreshAll(items: [itemA, itemB])

        // Manually record a session and tell the store to refresh.
        try sessionRepo.create(taskID: itemA.id)
        PomodoroSessionStore.shared.refresh(taskID: itemA.id)

        XCTAssertEqual(PomodoroSessionStore.shared.count(for: itemA.id), 1)
        XCTAssertEqual(PomodoroSessionStore.shared.count(for: itemB.id), 0)
    }
}
