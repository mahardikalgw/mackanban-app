//
//  KanbanViewModelTests.swift
//  TaskBarTests
//

import XCTest
import SwiftData
@testable import TaskBar

@MainActor
final class KanbanViewModelTests: XCTestCase {

    private func setupProject() throws -> (WorkItemRepository, ProjectRepository, Project) {
        try ModelContainerProvider.makeInMemoryRepositoryPair()
    }

    func testInitialLoadGroupsAllItemsByStatus() throws {
        let (workRepo, _, project) = try setupProject()
        _ = try workRepo.create(title: "A", status: .todo, project: project)
        _ = try workRepo.create(title: "B", status: .doing, project: project)
        _ = try workRepo.create(title: "C", status: .review, project: project)
        _ = try workRepo.create(title: "D", status: .done, project: project)
        let vm = KanbanViewModel(repository: workRepo)
        vm.selectedProject = project
        XCTAssertEqual(vm.groupedItems[.todo]?.count, 1)
        XCTAssertEqual(vm.groupedItems[.doing]?.count, 1)
        XCTAssertEqual(vm.groupedItems[.review]?.count, 1)
        XCTAssertEqual(vm.groupedItems[.done]?.count, 1)
    }

    func testSwitchingProjectReloadsItems() throws {
        let (workRepo, projRepo, project1) = try setupProject()
        let project2 = try projRepo.create(name: "Work")
        _ = try workRepo.create(title: "In P1", project: project1)
        _ = try workRepo.create(title: "In P2", project: project2)
        let vm = KanbanViewModel(repository: workRepo)
        vm.selectedProject = project1
        XCTAssertEqual(vm.items.count, 1)
        XCTAssertEqual(vm.items.first?.title, "In P1")
        vm.selectedProject = project2
        XCTAssertEqual(vm.items.count, 1)
        XCTAssertEqual(vm.items.first?.title, "In P2")
    }

    func testSearchFiltersAcrossFields() throws {
        let (workRepo, _, project) = try setupProject()
        _ = try workRepo.create(title: "Fix login bug", status: .todo, project: project)
        _ = try workRepo.create(title: "Write spec", status: .doing, project: project)
        _ = try workRepo.create(title: "Review PR", status: .review, tags: ["QA"], project: project)
        let vm = KanbanViewModel(repository: workRepo)
        vm.selectedProject = project
        XCTAssertEqual(vm.items.count, 3)
        vm.searchText = "review"
        let totalGrouped = vm.groupedItems.values.reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalGrouped, 1)
    }

    func testMoveAcrossColumnsPersists() throws {
        let (workRepo, _, project) = try setupProject()
        let vm = KanbanViewModel(repository: workRepo)
        vm.selectedProject = project
        let item = try workRepo.create(title: "Move me", project: project)
        vm.move(itemID: item.id, to: .review)
        XCTAssertEqual(try workRepo.find(id: item.id)?.status, .review)
    }

    func testDeleteRemovesItem() throws {
        let (workRepo, _, project) = try setupProject()
        let vm = KanbanViewModel(repository: workRepo)
        vm.selectedProject = project
        let item = try workRepo.create(title: "Delete me", project: project)
        vm.delete(itemID: item.id)
        XCTAssertNil(try workRepo.find(id: item.id))
    }

    // MARK: - Pomodoro session store integration

    func testReloadPopulatesPomodoroSessionStore() throws {
        let container = try ModelContainerProvider.makeInMemoryContainer()
        let context = ModelContext(container)
        let workRepo = WorkItemRepository(context: context)
        let projRepo = ProjectRepository(context: context)
        let project = try projRepo.create(name: "Test")
        // Attach the session store to the same context so it can query
        // PomodoroSession counts.
        PomodoroSessionStore.shared.reset()
        PomodoroSessionStore.shared.attach(context: context)
        let itemA = try workRepo.create(title: "A", project: project)
        let itemB = try workRepo.create(title: "B", project: project)
        let vm = KanbanViewModel(repository: workRepo)
        vm.selectedProject = project
        // Both items should have 0-count entries in the store.
        XCTAssertEqual(PomodoroSessionStore.shared.count(for: itemA.id), 0)
        XCTAssertEqual(PomodoroSessionStore.shared.count(for: itemB.id), 0)
    }
}
