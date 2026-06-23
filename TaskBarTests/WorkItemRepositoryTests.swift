//
//  WorkItemRepositoryTests.swift
//  TaskBarTests
//
//  XCTest suite for the WorkItem repository — flat tasks with
//  assignees (many-to-many with TeamMember).
//

import XCTest
import SwiftData
@testable import TaskBar

final class WorkItemRepositoryTests: XCTestCase {

    private func makeRepo() throws -> (WorkItemRepository, ProjectRepository, Project, TeamMemberRepository) {
        let container = try ModelContainerProvider.makeInMemoryContainer()
        let context = ModelContext(container)
        let workItemRepo = WorkItemRepository(context: context)
        let projectRepo = ProjectRepository(context: context)
        let memberRepo = TeamMemberRepository(context: context)
        let project = try projectRepo.create(name: "Personal", colorHex: "#5C95FF")
        return (workItemRepo, projectRepo, project, memberRepo)
    }

    // MARK: - Create

    func testCreatePersistsDefault() throws {
        let (repo, _, project, _) = try makeRepo()
        let item = try repo.create(title: "Write spec", project: project)
        XCTAssertEqual(item.title, "Write spec")
        XCTAssertEqual(item.status, .todo)
        XCTAssertEqual(item.priority, .medium)
        XCTAssertEqual(item.project?.id, project.id)
        XCTAssertTrue(item.tags.isEmpty)
        XCTAssertTrue(item.assignees.isEmpty)
    }

    func testCreateRejectsEmptyTitle() throws {
        let (repo, _, project, _) = try makeRepo()
        XCTAssertThrowsError(try repo.create(title: "   ", project: project)) { error in
            XCTAssertEqual(error as? WorkItemRepositoryError, .invalidTitle)
        }
    }

    func testCreateWithTagsStoresAsArray() throws {
        let (repo, _, project, _) = try makeRepo()
        let item = try repo.create(title: "Tag me", tags: ["urgent", "client", ""], project: project)
        XCTAssertEqual(item.tags, ["urgent", "client"])
    }

    func testCreateWithAssignees() throws {
        let (repo, _, project, memberRepo) = try makeRepo()
        let ava = try memberRepo.create(name: "Ava Chen")
        let leo = try memberRepo.create(name: "Leo Park")
        let item = try repo.create(title: "Pair on auth", project: project, assignees: [ava, leo])
        XCTAssertEqual(Set(item.assignees.map(\.id)), Set([ava.id, leo.id]))
    }

    // MARK: - Status

    func testUpdateStatusNoOpWhenSame() throws {
        let (repo, _, project, _) = try makeRepo()
        let item = try repo.create(title: "Stay put", project: project)
        let originalUpdated = item.updatedAt
        try repo.updateStatus(id: item.id, to: .todo)
        let reloaded = try repo.find(id: item.id)
        XCTAssertEqual(reloaded?.updatedAt, originalUpdated)
    }

    func testUpdateStatusMovesAcrossColumns() throws {
        let (repo, _, project, _) = try makeRepo()
        let item = try repo.create(title: "Move me", project: project)
        try repo.updateStatus(id: item.id, to: .review)
        XCTAssertEqual(try repo.find(id: item.id)?.status, .review)
        try repo.updateStatus(id: item.id, to: .done)
        XCTAssertEqual(try repo.find(id: item.id)?.status, .done)
    }

    // MARK: - Assignees

    func testSetAssigneesReplacesSet() throws {
        let (repo, _, project, memberRepo) = try makeRepo()
        let ava = try memberRepo.create(name: "Ava Chen")
        let leo = try memberRepo.create(name: "Leo Park")
        let mia = try memberRepo.create(name: "Mia Sato")
        let item = try repo.create(title: "Pair work", project: project, assignees: [ava, leo])
        try repo.setAssignees([mia], on: item.id)
        let reloaded = try repo.find(id: item.id)
        XCTAssertEqual(reloaded?.assignees.map(\.id), [mia.id])
    }

    func testSetAssigneesNoOpWhenIdentical() throws {
        let (repo, _, project, memberRepo) = try makeRepo()
        let ava = try memberRepo.create(name: "Ava Chen")
        let item = try repo.create(title: "Solo", project: project, assignees: [ava])
        let originalUpdated = try repo.find(id: item.id)?.updatedAt
        try repo.setAssignees([ava], on: item.id)
        XCTAssertEqual(try repo.find(id: item.id)?.updatedAt, originalUpdated)
    }

    func testDeletingItemClearsItsAssignments() throws {
        let (repo, _, project, memberRepo) = try makeRepo()
        let ava = try memberRepo.create(name: "Ava Chen")
        let item = try repo.create(title: "Will be deleted", project: project, assignees: [ava])
        try repo.delete(id: item.id)
        XCTAssertNil(try repo.find(id: item.id))
        // Member still exists; the many-to-many just dropped.
        XCTAssertNotNil(try memberRepo.find(id: ava.id))
    }

    // MARK: - Project filtering

    func testFetchByProjectFilters() throws {
        let (workItemRepo, projectRepo, project1, _) = try makeRepo()
        let project2 = try projectRepo.create(name: "Work", colorHex: "#FF0000")

        let w1 = try workItemRepo.create(title: "In P1", project: project1)
        _ = try workItemRepo.create(title: "In P2", project: project2)
        _ = try workItemRepo.create(title: "No project")

        let p1Items = try workItemRepo.fetch(project: project1)
        XCTAssertTrue(p1Items.contains(where: { $0.id == w1.id }))
        XCTAssertEqual(p1Items.count, 1)
    }
}
