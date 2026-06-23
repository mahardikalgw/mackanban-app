//
//  PomodoroTimerView.swift
//  TaskBar
//
//  SwiftUI content for the floating Pomodoro window.
//
//  Flow:
//  1. idle     → drop zone + duration selector + task picker
//  2. working  → countdown timer + pause/resume/reset
//  3. finished → "Time's up!" with Extend / Confirm Done buttons
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct PomodoroTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var timer = PomodoroTimer.shared

    var body: some View {
        Group {
            switch timer.phase {
            case .idle:
                idleContent
            case .working:
                activeContent
            case .finished:
                finishedContent
            }
        }
        .onChange(of: timer.phase) { _, _ in
            PomodoroWindowController.shared.resizeToFitCurrentPhase()
        }
    }

    // MARK: - Idle (drop zone + duration + task picker)

    private var idleContent: some View {
        VStack(spacing: 0) {
            dropZone
            Divider()
            durationSelector
            Divider()
            taskListSection
        }
        .frame(minWidth: 340, minHeight: 460)
        .background(windowBackground)
    }

    private var dropZone: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)
            Text(timer.pendingTaskTitle.isEmpty ? "Drop a task here" : timer.pendingTaskTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(timer.pendingTaskTitle.isEmpty ? .secondary : .primary)
            Text(timer.pendingTaskTitle.isEmpty ? "or pick one below" : "Press Start to begin")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            if !timer.pendingTaskTitle.isEmpty {
                startButton
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    Color.primary.opacity(0.15),
                    lineWidth: 1.5
                )
        )
        .padding(16)
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    private var startButton: some View {
        Button {
            if let taskID = timer.pendingTaskID {
                startWorkForTask(id: taskID)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("Start \(formatDuration(timer.selectedDurationSeconds))")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(Color(red: 0.83, green: 0.30, blue: 0.28))
            )
        }
        .buttonStyle(.plain)
    }

    private var durationSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            HStack(spacing: 8) {
                ForEach(PomodoroTimer.presets, id: \.seconds) { preset in
                    let isSelected = timer.selectedDurationSeconds == preset.seconds
                    Button {
                        timer.selectedDurationSeconds = preset.seconds
                    } label: {
                        Text(preset.label)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(isSelected ? Color(red: 0.83, green: 0.30, blue: 0.28) : Color.primary.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var taskListSection: some View {
        if let context = PomodoroWindowController.shared.modelContext {
            PomodoroTaskPickerView()
                .environment(\.modelContext, context)
        }
    }

    // MARK: - Working (countdown)

    private var activeContent: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let remaining = timer.secondsRemaining(now: context.date)
            let progress = timer.progress(now: context.date)

            VStack(spacing: 12) {
                HStack {
                    phaseBadge
                    Spacer()
                    resetButton
                }
                Text(timeString(remaining))
                    .font(.system(size: 52, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                taskLine
                ProgressView(value: progress)
                    .tint(Color(red: 0.83, green: 0.30, blue: 0.28))
                controls
            }
            .padding(20)
            .frame(width: 280)
            .background(windowBackground)
        }
    }

    private var phaseBadge: some View {
        Text("FOCUS")
            .font(.system(size: 11, weight: .heavy))
            .tracking(1.4)
            .foregroundStyle(Color(red: 0.78, green: 0.30, blue: 0.28))
    }

    @ViewBuilder
    private var taskLine: some View {
        if !timer.currentTaskTitle.isEmpty {
            Text(timer.currentTaskTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            Text(" ").font(.system(size: 13))
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                togglePlayPause()
            } label: {
                Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.primary.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
    }

    private var resetButton: some View {
        Button {
            timer.reset()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Finished (Extend / Confirm Done)

    private var finishedContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(red: 0.30, green: 0.58, blue: 0.46))
            Text("Time's up!")
                .font(.system(size: 18, weight: .bold))
            if !timer.currentTaskTitle.isEmpty {
                Text(timer.currentTaskTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            Divider()
            VStack(spacing: 10) {
                Text("What's next?")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                extendButton
                confirmDoneButton
            }
        }
        .padding(20)
        .frame(width: 280)
        .background(windowBackground)
    }

    private var extendButton: some View {
        Button {
            timer.extend(byMinutes: 5)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 13, weight: .semibold))
                Text("Extend +5 min")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }

    private var confirmDoneButton: some View {
        Button {
            let repo = WorkItemRepository(context: modelContext)
            timer.confirmDone(repository: repo)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                Text("Confirm Done → Review")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.30, green: 0.58, blue: 0.46))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Drop handling

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let str = object as? String, let uuid = UUID(uuidString: str) else { return }
            Task { @MainActor in
                let repo = WorkItemRepository(context: self.modelContext)
                guard let task = try? repo.find(id: uuid) else { return }
                try? repo.updateStatus(id: uuid, to: .doing)
                NotificationCenter.default.post(name: .pomodoroTaskStatusChanged, object: nil)
                PomodoroTimer.shared.selectTask(
                    id: task.id,
                    title: task.title,
                    projectID: task.project?.id
                )
            }
        }
        return true
    }

    private func startWorkForTask(id: UUID) {
        let repo = WorkItemRepository(context: modelContext)
        guard let task = try? repo.find(id: id) else { return }
        // Move to in-progress if not already
        if task.status != .doing {
            try? repo.updateStatus(id: id, to: .doing)
            NotificationCenter.default.post(name: .pomodoroTaskStatusChanged, object: nil)
        }
        PomodoroTimer.shared.startWork(task: task)
    }

    // MARK: - Helpers

    private var windowBackground: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            LinearGradient(
                colors: [Color.white.opacity(0.10), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        }
        .ignoresSafeArea()
    }

    private func togglePlayPause() {
        if timer.isRunning {
            timer.pause()
        } else if timer.isPaused {
            timer.resume()
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        return "\(m) min"
    }
}

#Preview {
    PomodoroTimerView()
        .frame(width: 300, height: 400)
}
