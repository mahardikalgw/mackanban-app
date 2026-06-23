//
//  TeamMemberRepositoryTests.swift
//  TaskBarTests
//

import XCTest
import SwiftData
@testable import TaskBar

final class TeamMemberRepositoryTests: XCTestCase {

    private func makeRepo() throws -> (TeamMemberRepository, ModelContext) {
        let container = try ModelContainerProvider.makeInMemoryContainer()
        let context = ModelContext(container)
        return (TeamMemberRepository(context: context), context)
    }

    func testCreatePersistsNameAndDefaults() throws {
        let (repo, _) = try makeRepo()
        let member = try repo.create(name: "Ava Chen")
        XCTAssertEqual(member.name, "Ava Chen")
        XCTAssertEqual(member.initials, "AC")
        XCTAssertFalse(member.colorHex.isEmpty)
        XCTAssertNil(member.role)
    }

    func testCreateWithRole() throws {
        let (repo, _) = try makeRepo()
        let member = try repo.create(name: "Leo Park", role: "Engineer")
        XCTAssertEqual(member.role, "Engineer")
    }

    func testCreateRejectsEmptyName() throws {
        let (repo, _) = try makeRepo()
        XCTAssertThrowsError(try repo.create(name: "   ")) { error in
            XCTAssertEqual(error as? TeamMemberRepositoryError, .invalidName)
        }
    }

    func testInitialsHandleSingleName() throws {
        let (repo, _) = try makeRepo()
        let member = try repo.create(name: "Madonna")
        XCTAssertEqual(member.initials, "M")
    }

    func testColorIsDeterministic() throws {
        let (repo, _) = try makeRepo()
        let a = try repo.create(name: "Ava Chen")
        let b = try repo.create(name: "Ava Chen")
        XCTAssertEqual(a.colorHex, b.colorHex)
    }

    func testFetchAllReturnsByCreatedAt() throws {
        let (repo, _) = try makeRepo()
        let first = try repo.create(name: "First")
        Thread.sleep(forTimeInterval: 0.02)
        let second = try repo.create(name: "Second")
        let all = try repo.fetchAll()
        XCTAssertEqual(all.firstIndex(where: { $0.id == first.id }), 0)
        XCTAssertEqual(all.firstIndex(where: { $0.id == second.id }), 1)
    }

    func testUpdateModifiesFields() throws {
        let (repo, _) = try makeRepo()
        let member = try repo.create(name: "Old")
        try repo.update(id: member.id) { $0.name = "New"; $0.role = "PM" }
        let reloaded = try repo.find(id: member.id)
        XCTAssertEqual(reloaded?.name, "New")
        XCTAssertEqual(reloaded?.role, "PM")
    }

    func testDeleteRemovesMember() throws {
        let (repo, _) = try makeRepo()
        let member = try repo.create(name: "Doomed")
        try repo.delete(id: member.id)
        XCTAssertNil(try repo.find(id: member.id))
    }
}
