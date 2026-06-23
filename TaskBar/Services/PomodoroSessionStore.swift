//
//  PomodoroSessionStore.swift
//  TaskBar
//
//  Caches per-task completed-Pomodoro counts so kanban cards can show
//  "🍅 N" badges without each card running its own SwiftData query.
//
//  The store is a singleton @Observable. Views observe it via @State
//  (Observation framework). It listens for the existing
//  `.pomodoroWorkSessionCompleted` notification and refreshes the
//  affected task's count via `PomodoroSessionRepository.count(taskID:)`.
//
//  `KanbanViewModel.reload()` calls `refreshAll(items:)` so the cache
//  stays in sync when tasks are loaded/created/deleted.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class PomodoroSessionStore {
    static let shared = PomodoroSessionStore()

    /// taskID → completed Pomodoro count. Missing keys imply 0.
    private(set) var counts: [UUID: Int] = [:]

    private var repository: PomodoroSessionRepository?
    private var observer: NSObjectProtocol?
    private var isAttached = false

    private init() {}

    /// Wire the store to a model context and start listening for
    /// completed sessions. Idempotent — safe to call multiple times.
    func attach(context: ModelContext) {
        if isAttached {
            // Context may have changed (e.g. after a container swap);
            // update the repository but don't add a second observer.
            repository = PomodoroSessionRepository(context: context)
            return
        }
        repository = PomodoroSessionRepository(context: context)
        isAttached = true
        observer = NotificationCenter.default.addObserver(
            forName: .pomodoroWorkSessionCompleted,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let taskID = note.userInfo?["taskID"] as? UUID else { return }
            Task { @MainActor in self.refresh(taskID: taskID) }
        }
    }

    /// Refresh counts for a set of tasks. Called by
    /// `KanbanViewModel.reload()` after items are loaded.
    func refreshAll(items: [WorkItem]) {
        guard let repository else { return }
        for item in items {
            let count = (try? repository.count(taskID: item.id)) ?? 0
            counts[item.id] = count
        }
        // Drop keys for items no longer present.
        let visibleIDs = Set(items.map(\.id))
        for key in counts.keys where !visibleIDs.contains(key) {
            counts.removeValue(forKey: key)
        }
    }

    /// Refresh a single task's count. Called after a session completes.
    func refresh(taskID: UUID) {
        guard let repository else { return }
        counts[taskID] = (try? repository.count(taskID: taskID)) ?? 0
    }

    /// Count for a task (0 if unknown).
    func count(for taskID: UUID) -> Int {
        counts[taskID] ?? 0
    }

    /// Clear the cache (used by tests).
    func reset() {
        counts.removeAll()
    }
}
