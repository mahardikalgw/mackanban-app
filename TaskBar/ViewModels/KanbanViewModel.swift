//
//  KanbanViewModel.swift
//  TaskBar
//
//  Board state for a single project: items loaded from the repository,
//  grouped by status, optionally filtered by a search query.
//

import Foundation
import Observation
import SwiftUI

@Observable
final class KanbanViewModel {
    /// Selected project. Switching projects triggers a reload.
    var selectedProject: Project? {
        didSet { if selectedProject?.id != oldValue?.id { reload() } }
    }

    /// User-facing search query.
    var searchText: String = "" {
        didSet { if searchText != oldValue { recompute() } }
    }

    /// Raw items loaded from the repository, filtered to the selected project.
    private(set) var items: [WorkItem] = []

    /// Items grouped by status, after applying filters.
    private(set) var groupedItems: [TaskStatus: [WorkItem]] = [:]

    /// Last error encountered.
    private(set) var lastError: Error?

    private let repository: WorkItemRepository

    init(repository: WorkItemRepository) {
        self.repository = repository
        reload()
    }

    /// Re-fetch items for the current project and recompute groupings.
    func reload() {
        do {
            if let project = selectedProject {
                items = try repository.fetch(project: project)
            } else {
                items = try repository.fetchAll()
            }
            lastError = nil
        } catch {
            items = []
            lastError = error
        }
        // Keep the Pomodoro session-count cache in sync with the
        // currently visible tasks so card badges stay accurate.
        let snapshot = items
        Task { @MainActor in
            PomodoroSessionStore.shared.refreshAll(items: snapshot)
        }
        recompute()
    }

    /// Move a work item to a new status. Persists, then refreshes.
    /// The `withAnimation` block drives the cross-column move via
    /// `matchedGeometryEffect` on each card.
    func move(itemID: UUID, to status: TaskStatus) {
        do {
            try repository.updateStatus(id: itemID, to: status)
            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.85)) {
                reload()
            }
        } catch {
            lastError = error
        }
    }

    /// Delete a work item by id. Persists, then refreshes.
    func delete(itemID: UUID) {
        do {
            try repository.delete(id: itemID)
            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.85)) {
                reload()
            }
        } catch {
            lastError = error
        }
    }

    private func recompute() {
        let filtered = SearchService.filter(items: items, query: searchText)
        var grouped = SearchService.groupByStatus(filtered)
        for (status, bucket) in grouped {
            grouped[status] = SearchService.sortForColumn(bucket)
        }
        groupedItems = grouped
    }
}
