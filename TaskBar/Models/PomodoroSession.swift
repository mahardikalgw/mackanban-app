//
//  PomodoroSession.swift
//  TaskBar
//
//  Records one completed work session for a task. Stored locally so
//  the user can see how many Pomodoros they've spent on each task.
//  We keep a `taskID` (UUID) rather than a `WorkItem` reference so
//  deleting a task doesn't accidentally cascade-delete its history.
//

import Foundation
import SwiftData

@Model
final class PomodoroSession {
    @Attribute(.unique) var id: UUID
    /// ID of the task this session belongs to. Storing the ID rather
    /// than the reference keeps the relation uni-directional and
    /// avoids cascade surprises on task deletion.
    var taskID: UUID
    /// When the work phase finished.
    var completedAt: Date
    /// Length of the completed work phase in seconds (typically 1500).
    var durationSeconds: Int

    init(
        id: UUID = UUID(),
        taskID: UUID,
        completedAt: Date = .now,
        durationSeconds: Int = 25 * 60
    ) {
        self.id = id
        self.taskID = taskID
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
    }
}
