//
//  PomodoroTimerTests.swift
//  TaskBarTests
//
//  State-machine tests for the Pomodoro timer. Drives `tick()` with
//  controlled `now:` arguments rather than waiting on wall-clock
//  time so the suite stays fast and deterministic.
//

import XCTest
@testable import TaskBar

@MainActor
final class PomodoroTimerTests: XCTestCase {

    override func setUp() async throws {
        PomodoroTimer.shared.reset()
    }

    override func tearDown() async throws {
        PomodoroTimer.shared.reset()
    }

    func testInitialStateIsIdle() {
        let timer = PomodoroTimer.shared
        XCTAssertEqual(timer.phase, .idle)
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.isPaused)
        XCTAssertEqual(timer.secondsRemaining(), 0)
    }

    func testStartWorkSetsRunningPhaseAndCountdown() {
        let timer = PomodoroTimer.shared
        let task = WorkItem(title: "Write spec")
        timer.startWork(task: task)

        XCTAssertEqual(timer.phase, .work(taskID: task.id))
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.currentTaskTitle, "Write spec")
        // Within 1 second of the full work duration, the countdown is
        // still essentially the full duration.
        XCTAssertGreaterThan(timer.secondsRemaining(), timer.workDurationSeconds - 1)
        XCTAssertLessThanOrEqual(timer.secondsRemaining(), timer.workDurationSeconds)
    }

    func testPauseAndResumePreservesRemainingSeconds() {
        let timer = PomodoroTimer.shared
        let task = WorkItem(title: "Write spec")
        timer.startWork(task: task)
        timer.pause()

        XCTAssertTrue(timer.isPaused)
        XCTAssertFalse(timer.isRunning)
        let pausedAt = timer.secondsRemaining()

        // While paused, secondsRemaining must not change with `now`.
        XCTAssertEqual(timer.secondsRemaining(now: .now.addingTimeInterval(60)), pausedAt)

        timer.resume()
        XCTAssertTrue(timer.isRunning)
        XCTAssertFalse(timer.isPaused)
    }

    func testTickAtEndDateAdvancesToBreak() {
        let timer = PomodoroTimer.shared
        let task = WorkItem(title: "Write spec")
        timer.startWork(task: task)
        XCTAssertEqual(timer.phase, .work(taskID: task.id))

        // Jump the clock past the work endDate.
        if let end = timer.endDate {
            timer.tick(now: end.addingTimeInterval(0.5))
        }
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.completedWorkSessions, 1)
    }

    func testTickAtBreakEndReturnsToIdle() {
        let timer = PomodoroTimer.shared
        let task = WorkItem(title: "Write spec")
        timer.startWork(task: task)
        if let end = timer.endDate {
            timer.tick(now: end.addingTimeInterval(0.5))
        }
        XCTAssertEqual(timer.phase, .shortBreak)
        if let end = timer.endDate {
            timer.tick(now: end.addingTimeInterval(0.5))
        }
        XCTAssertEqual(timer.phase, .idle)
        XCTAssertTrue(timer.currentTaskTitle.isEmpty)
    }

    func testResetReturnsToIdle() {
        let timer = PomodoroTimer.shared
        let task = WorkItem(title: "Write spec")
        timer.startWork(task: task)
        timer.pause()

        timer.reset()
        XCTAssertEqual(timer.phase, .idle)
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.isPaused)
        XCTAssertEqual(timer.secondsRemaining(), 0)
    }

    func testSkipFromWorkGoesToBreakWithoutCountingCompletion() {
        let timer = PomodoroTimer.shared
        let task = WorkItem(title: "Write spec")
        timer.startWork(task: task)
        timer.skip()
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.completedWorkSessions, 0)
    }

    func testSkipFromBreakReturnsToIdle() {
        let timer = PomodoroTimer.shared
        let task = WorkItem(title: "Write spec")
        timer.startWork(task: task)
        // Advance to break.
        if let end = timer.endDate {
            timer.tick(now: end.addingTimeInterval(0.5))
        }
        timer.skip()
        XCTAssertEqual(timer.phase, .idle)
    }

    func testIsActiveTaskMatchesOnlyTheCurrentWorkPhase() {
        let timer = PomodoroTimer.shared
        let taskA = WorkItem(title: "Task A")
        let taskB = WorkItem(title: "Task B")

        // Idle: nothing is active.
        XCTAssertFalse(timer.isActiveTask(taskID: taskA.id))
        XCTAssertFalse(timer.isActiveTask(taskID: taskB.id))

        timer.startWork(task: taskA)
        XCTAssertTrue(timer.isActiveTask(taskID: taskA.id))
        XCTAssertFalse(timer.isActiveTask(taskID: taskB.id))

        // Switching tasks mid-flight moves the active pointer.
        timer.startWork(task: taskB)
        XCTAssertFalse(timer.isActiveTask(taskID: taskA.id))
        XCTAssertTrue(timer.isActiveTask(taskID: taskB.id))

        // After advancing into a break, no task is "active".
        if let end = timer.endDate {
            timer.tick(now: end.addingTimeInterval(0.5))
        }
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertFalse(timer.isActiveTask(taskID: taskB.id))
    }

    func testProgressIsZeroAtStartAndApproachesOneAtEnd() {
        let timer = PomodoroTimer.shared
        let task = WorkItem(title: "Write spec")
        timer.startWork(task: task)
        XCTAssertEqual(timer.progress(), 0)

        if let end = timer.endDate {
            timer.tick(now: end.addingTimeInterval(0.5))
            // After advancing to break, progress resets for the new phase.
            XCTAssertEqual(timer.progress(), 0)
        }
    }

    func testStartWorkWithSameTaskIsNoOp() {
        let timer = PomodoroTimer.shared
        let task = WorkItem(title: "No double-fire")
        timer.startWork(task: task)
        let initialPhase = timer.phase
        let initialEndDate = timer.endDate

        timer.startWork(task: task)

        // Phase and end date must not change.
        XCTAssertEqual(
            timer.phase, initialPhase,
            "Starting the same task again should be a no-op"
        )
        if let initial = initialEndDate, let current = timer.endDate {
            XCTAssertEqual(current.timeIntervalSinceReferenceDate,
                           initial.timeIntervalSinceReferenceDate,
                           accuracy: 0.5)
        } else {
            XCTFail("endDate should be set after startWork")
        }
    }

    func testSetCurrentProjectIDOnStartWork() {
        let timer = PomodoroTimer.shared
        let project = Project(name: "My Project")
        let task = WorkItem(title: "In a project", project: project)

        timer.startWork(task: task)

        XCTAssertEqual(timer.currentProjectID, project.id)
    }

    func testResetClearsCurrentProjectID() {
        let timer = PomodoroTimer.shared
        let project = Project(name: "My Project")
        let task = WorkItem(title: "In a project", project: project)

        timer.startWork(task: task)
        XCTAssertEqual(timer.currentProjectID, project.id)

        timer.reset()
        XCTAssertNil(timer.currentProjectID)
    }
}
