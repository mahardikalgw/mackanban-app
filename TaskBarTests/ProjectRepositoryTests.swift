//
//  ProjectRepositoryTests.swift
//  TaskBarTests
//

import XCTest
@testable import TaskBar

final class ProjectRepositoryTests: XCTestCase {

    func testSeedCreatesDefaultProject() throws {
        let repo = try ModelContainerProvider.makeInMemoryProjectRepository()
        let all = try repo.fetchAll()
        XCTAssertFalse(all.isEmpty)
        XCTAssertEqual(all.first?.name, "Personal")
    }

    func testCreateRejectsEmptyName() throws {
        let repo = try ModelContainerProvider.makeInMemoryProjectRepository()
        XCTAssertThrowsError(try repo.create(name: "   ")) { error in
            XCTAssertEqual(error as? ProjectRepositoryError, .invalidName)
        }
    }

    func testCreatePersistsNameAndColor() throws {
        let repo = try ModelContainerProvider.makeInMemoryProjectRepository()
        let project = try repo.create(name: "Work", colorHex: "#FF0000")
        XCTAssertEqual(project.name, "Work")
        XCTAssertEqual(project.colorHex, "#FF0000")
    }

    func testFetchAllReturnsByCreatedAtOrder() throws {
        let repo = try ModelContainerProvider.makeInMemoryProjectRepository()
        let p1 = try repo.create(name: "First")
        Thread.sleep(forTimeInterval: 0.05)
        let p2 = try repo.create(name: "Second")
        let all = try repo.fetchAll()
        let p1Index = all.firstIndex(where: { $0.id == p1.id })
        let p2Index = all.firstIndex(where: { $0.id == p2.id })
        XCTAssertNotNil(p1Index)
        XCTAssertNotNil(p2Index)
        XCTAssertLessThan(p1Index!, p2Index!)
    }

    func testUpdateModifiesName() throws {
        let repo = try ModelContainerProvider.makeInMemoryProjectRepository()
        let project = try repo.create(name: "Old")
        try repo.update(id: project.id) { $0.name = "New" }
        XCTAssertEqual(try repo.find(id: project.id)?.name, "New")
    }

    func testDeleteRemovesProject() throws {
        let repo = try ModelContainerProvider.makeInMemoryProjectRepository()
        let project = try repo.create(name: "Delete me")
        try repo.delete(id: project.id)
        XCTAssertNil(try repo.find(id: project.id))
    }

    /// XCTest isn't async, so use a small synchronous sleep helper.
    private func awaitTask() {
        let until = Date().addingTimeInterval(0.01)
        while Date() < until { /* spin briefly */ }
    }
}
