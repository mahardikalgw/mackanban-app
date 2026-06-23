//
//  PomodoroTimer.swift
//  TaskBar
//
//  State machine + countdown for the Pomodoro timer.
//
//  Revised flow:
//  1. User drops a task onto the Pomodoro panel → task status auto-moves
//     to "In Progress" and the timer starts with the user-chosen duration.
//  2. Timer counts down → when it hits 0, enters `.finished` state.
//  3. User can "Extend" (add more time) or "Confirm Done" (task moves to
//     "Review" and timer returns to idle).
//
//  - `endDate` is set while a phase is actively counting down.
//  - `secondsRemainingWhenPaused` is set while a phase is paused.
//  - `tick()` is called every second by an internal `Timer`.
//
//  When a work phase completes, the timer posts
//  `.pomodoroWorkSessionCompleted` so the app layer can persist the
//  session via `PomodoroSessionRepository`.
//

import Foundation
import Observation
import UserNotifications

enum PomodoroPhase: Equatable {
    case idle
    case working(taskID: UUID)
    case finished(taskID: UUID)
}

/// Posted when a task's status is changed from the Pomodoro panel
/// (dropped → In Progress, or Confirm Done → Review). The kanban
/// view model listens for this to reload the board.
extension Notification.Name {
    static let pomodoroWorkSessionCompleted = Notification.Name("TaskBar.pomodoroWorkSessionCompleted")
    static let pomodoroTaskStatusChanged = Notification.Name("TaskBar.pomodoroTaskStatusChanged")
}

@Observable
@MainActor
final class PomodoroTimer {
    /// Shared instance — there's exactly one Pomodoro at a time.
    static let shared = PomodoroTimer()

    /// Current phase of the timer.
    private(set) var phase: PomodoroPhase = .idle

    /// Title of the task being worked on (empty when idle).
    private(set) var currentTaskTitle: String = ""

    /// ID of the project the currently-selected task belongs to.
    private(set) var currentProjectID: UUID?

    /// When the current phase ends. `nil` when idle, paused, or finished.
    private(set) var endDate: Date?

    /// Seconds remaining when paused. `nil` when idle or running.
    private(set) var secondsRemainingWhenPaused: Int?

    /// Lifetime count of work phases completed in this session.
    private(set) var completedWorkSessions: Int = 0

    /// The task the user dropped onto the panel but hasn't started yet.
    /// Set when a task is dropped; cleared when the timer starts or resets.
    private(set) var pendingTaskID: UUID?
    private(set) var pendingTaskTitle: String = ""

    /// Called when a task is dropped onto the Pomodoro panel.
    /// Sets the pending task so the user can choose a duration and start.
    func selectTask(id: UUID, title: String, projectID: UUID?) {
        reset()
        pendingTaskID = id
        pendingTaskTitle = title
        currentProjectID = projectID
    }

    /// User-selected duration for the next work session, in seconds.
    /// Defaults to 25 minutes. Changed via the duration picker in the
    /// panel UI before a task is dropped.
    var selectedDurationSeconds: Int = 25 * 60

    /// The duration that was used for the *currently running* session.
    /// Needed so `progress()` can compute correctly after the user
    /// changes `selectedDurationSeconds` for the next session.
    private(set) var activeDurationSeconds: Int = 25 * 60

    /// Preset durations offered in the UI.
    static let presets: [(label: String, seconds: Int)] = [
        ("15 min", 15 * 60),
        ("25 min", 25 * 60),
        ("45 min", 45 * 60),
        ("60 min", 60 * 60),
    ]

    private var ticker: Timer?

    // MARK: - Derived state

    var isRunning: Bool { endDate != nil }
    var isPaused: Bool { secondsRemainingWhenPaused != nil }
    var isFinished: Bool {
        if case .finished = phase { return true }
        return false
    }

    /// True when the timer's current work phase belongs to the given
    /// task. Used by the kanban card UI to render an "active" badge.
    func isActiveTask(taskID: UUID) -> Bool {
        if case .working(let activeID) = phase { return activeID == taskID }
        if case .finished(let activeID) = phase { return activeID == taskID }
        return false
    }

    /// The taskID currently being worked on (or just finished), if any.
    var activeTaskID: UUID? {
        switch phase {
        case .working(let id): return id
        case .finished(let id): return id
        case .idle: return nil
        }
    }

    /// Seconds remaining in the current phase.
    func secondsRemaining(now: Date = .now) -> Int {
        if let paused = secondsRemainingWhenPaused { return paused }
        guard let endDate else { return 0 }
        return max(0, Int(endDate.timeIntervalSince(now).rounded(.up)))
    }

    /// Progress of the current phase, 0...1.
    func progress(now: Date = .now) -> Double {
        guard activeDurationSeconds > 0 else { return 0 }
        let remaining = Double(secondsRemaining(now: now))
        return min(1, max(0, 1 - remaining / Double(activeDurationSeconds)))
    }

    // MARK: - Actions

    /// Begin a work phase for the given task using `selectedDurationSeconds`.
    /// Called when a task is dropped onto the Pomodoro panel.
    func startWork(task: WorkItem) {
        if case .working(let activeID) = phase, activeID == task.id {
            return
        }
        currentTaskTitle = task.title
        currentProjectID = task.project?.id
        phase = .working(taskID: task.id)
        activeDurationSeconds = selectedDurationSeconds
        beginPhase(durationSeconds: selectedDurationSeconds)
    }

    /// Add more time to the current task. Called from the "Extend"
    /// button when the timer has finished.
    func extend(byMinutes minutes: Int = 5) {
        guard case .finished(let taskID) = phase else { return }
        phase = .working(taskID: taskID)
        activeDurationSeconds = minutes * 60
        beginPhase(durationSeconds: minutes * 60)
    }

    /// Confirm the task is done. Moves the task to "Review" status
    /// via the provided repository, then returns to idle.
    func confirmDone(repository: WorkItemRepository) {
        guard case .finished(let taskID) = phase else { return }
        try? repository.updateStatus(id: taskID, to: .review)
        NotificationCenter.default.post(name: .pomodoroTaskStatusChanged, object: nil)
        reset()
    }

    /// Pause the active phase. No-op when idle/finished.
    func pause() {
        guard let endDate else { return }
        secondsRemainingWhenPaused = max(0, Int(endDate.timeIntervalSince(.now).rounded(.up)))
        self.endDate = nil
        stopTicker()
    }

    /// Resume a paused phase. No-op when not paused.
    func resume() {
        guard let paused = secondsRemainingWhenPaused else { return }
        beginPhase(durationSeconds: paused)
    }

    /// Stop the timer and return to idle.
    func reset() {
        stopTicker()
        cancelPendingNotification()
        endDate = nil
        secondsRemainingWhenPaused = nil
        phase = .idle
        currentTaskTitle = ""
        currentProjectID = nil
    }

    // MARK: - Ticking

    /// Called by the internal `Timer` once per second.
    func tick(now: Date = .now) {
        guard let endDate else { return }
        if now >= endDate {
            self.endDate = nil
            stopTicker()
            cancelPendingNotification()
            finishWork()
        }
    }

    // MARK: - Internal

    private func beginPhase(durationSeconds: Int) {
        endDate = Date.now.addingTimeInterval(TimeInterval(durationSeconds))
        secondsRemainingWhenPaused = nil
        stopTicker()
        scheduleNotification(in: TimeInterval(durationSeconds))
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    /// Called when the timer reaches 0. Transitions to `.finished`
    /// and posts the completion notification.
    private func finishWork() {
        guard case .working(let taskID) = phase else { return }
        completedWorkSessions += 1
        NotificationCenter.default.post(
            name: .pomodoroWorkSessionCompleted,
            object: nil,
            userInfo: ["taskID": taskID]
        )
        phase = .finished(taskID: taskID)
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func scheduleNotification(in interval: TimeInterval) {
        guard interval > 0 else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro complete!"
        content.body = currentTaskTitle.isEmpty
            ? "Time's up. Extend or confirm done."
            : "“\(currentTaskTitle)” — extend or confirm done?"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pomodoro-end",
            content: content,
            trigger: trigger
        )
        center.removePendingNotificationRequests(withIdentifiers: ["pomodoro-end"])
        center.add(request)
    }

    private func cancelPendingNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["pomodoro-end"])
    }
}
