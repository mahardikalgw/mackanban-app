//
//  SearchService.swift
//  TaskBar
//
//  Pure-logic filter / group / sort over WorkItem arrays.
//

import Foundation

enum SearchService {
    /// Filter items by `query`. Matches are case-insensitive substring against:
    /// - title
    /// - description
    /// - any tag
    /// - status display label and common synonyms
    static func filter(items: [WorkItem], query: String) -> [WorkItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        let needle = trimmed.lowercased()

        return items.filter { item in
            if item.title.lowercased().contains(needle) { return true }
            if item.itemDescription.lowercased().contains(needle) { return true }
            if item.tags.contains(where: { $0.lowercased().contains(needle) }) { return true }
            if item.status.searchKey.contains(needle) { return true }
            if item.status.aliasKeys.contains(where: { $0.contains(needle) }) { return true }
            return false
        }
    }

    /// Group items by status, returning a dictionary keyed by `TaskStatus`.
    /// Empty buckets are still present so the UI can render column headers.
    static func groupByStatus(_ items: [WorkItem]) -> [TaskStatus: [WorkItem]] {
        var buckets: [TaskStatus: [WorkItem]] = [:]
        for status in TaskStatus.allCases {
            buckets[status] = []
        }
        for item in items {
            buckets[item.status, default: []].append(item)
        }
        return buckets
    }

    /// Sort items within a column by priority (high → low), then by createdAt desc.
    static func sortForColumn(_ items: [WorkItem]) -> [WorkItem] {
        items.sorted { lhs, rhs in
            if lhs.priority.sortWeight != rhs.priority.sortWeight {
                return lhs.priority.sortWeight < rhs.priority.sortWeight
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
}
