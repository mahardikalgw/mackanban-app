//
//  SearchServiceTests.swift
//  TaskBarTests
//

import XCTest
@testable import TaskBar

final class SearchServiceTests: XCTestCase {

    private func setupProject() throws -> (WorkItemRepository, Project) {
        let (workRepo, _, project) = try ModelContainerProvider.makeInMemoryRepositoryPair()
        return (workRepo, project)
    }

    func testEmptyQueryReturnsAllItems() throws {
        let (repo, project) = try setupProject()
        _ = try repo.create(title: "X", project: project)
        _ = try repo.create(title: "Y", project: project)
        let all = try repo.fetch(project: project)
        XCTAssertEqual(SearchService.filter(items: all, query: "").count, all.count)
        XCTAssertEqual(SearchService.filter(items: all, query: "   ").count, all.count)
    }

    func testFilterMatchesTitleCaseInsensitively() throws {
        let (repo, project) = try setupProject()
        _ = try repo.create(title: "Fix login bug", project: project)
        _ = try repo.create(title: "Write spec", project: project)
        let all = try repo.fetch(project: project)
        let matches = SearchService.filter(items: all, query: "LOG")
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.title, "Fix login bug")
    }

    func testFilterMatchesReviewStatus() throws {
        let (repo, project) = try setupProject()
        _ = try repo.create(title: "Pending QA", status: .review, project: project)
        _ = try repo.create(title: "Active", status: .doing, project: project)
        let all = try repo.fetch(project: project)
        let matches = SearchService.filter(items: all, query: "review")
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.status, .review)
    }

    func testGroupByStatusIncludesAllStatuses() throws {
        let grouped = SearchService.groupByStatus([])
        XCTAssertEqual(Set(grouped.keys), Set(TaskStatus.allCases))
        XCTAssertTrue(grouped.values.allSatisfy(\.isEmpty))
    }
}
