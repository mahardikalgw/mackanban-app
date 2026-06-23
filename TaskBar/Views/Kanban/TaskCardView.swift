//
//  TaskCardView.swift
//  TaskBar
//
//  Notion-style card: warm white surface, subtle border. Reads colors
//  from \.theme.
//
//  Layout:
//  - Top row: priority badge + due-date pill + focus pill + play button
//  - Title (semibold, max 3 lines)
//  - Bottom row: tags
//
//  Badges and tag chips are built from the shared `Pill` component.
//
//  Cross-column "move" animation is driven by `matchedGeometryEffect`
//  using the namespace threaded down from `KanbanBoardView`. SwiftUI
//  interpolates the card's frame between the old and new column so
//  the move reads as a single smooth slide rather than fade-out +
//  fade-in at the destination.
//

import SwiftUI

struct TaskCardView: View {
    let task: WorkItem
    let namespace: Namespace.ID

    @Environment(\.theme) private var theme
    @State private var isHovering: Bool = false
    @State private var timer = PomodoroTimer.shared
    @State private var sessionStore = PomodoroSessionStore.shared

    private var isActiveTask: Bool {
        timer.isActiveTask(taskID: task.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            metaRow
            Text(task.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            if hasLowerRow {
                lowerRow
            }
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 22)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isHovering ? theme.cardBgHover : theme.cardBg)
        )
        .overlay(
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isActiveTask ? timerPhaseColor : (isHovering ? theme.cardBorderHover : theme.cardBorder),
                        lineWidth: isActiveTask ? 1.5 : 1
                    )
                if isActiveTask {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(timerPhaseColor)
                        .frame(width: 4, height: 36)
                        .padding(.top, 16)
                        .padding(.leading, 8)
                }
            }
        )
        .shadow(
            color: theme.shadow.opacity(isHovering ? 0.08 : 0.04),
            radius: isHovering ? 14 : 8,
            x: 0,
            y: isHovering ? 6 : 2
        )
        .contentShape(Rectangle())
        .draggable(task.id.uuidString)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .matchedGeometryEffect(id: task.id, in: namespace, isSource: !isHovering)
        .transition(.opacity)
    }

    private var timerPhaseColor: Color {
        switch timer.phase {
        case .working: return Color(red: 0.83, green: 0.30, blue: 0.28)
        case .finished: return Color(red: 0.80, green: 0.57, blue: 0.18)
        case .idle: return Color(red: 0.30, green: 0.58, blue: 0.46)
        }
    }

    // MARK: - Meta row (priority badge + due date + focus controls)

    private var metaRow: some View {
        HStack(spacing: 10) {
            Pill(
                text: task.priority.displayName,
                dotColor: task.priority.dotColor
            )
            if isActiveTask {
                focusPill
            }
            Spacer(minLength: 0)
            if let dueDate = task.dueDate {
                Pill(
                    text: dueDate.formatted(.dateTime.month(.abbreviated).day()),
                    icon: "calendar",
                    foreground: dueDateColor(dueDate)
                )
            }
        }
    }

    /// Small pill showing "Focus" when this task is the active Pomodoro.
    private var focusPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 10, weight: .semibold))
            Text("Focus")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(timerPhaseColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(timerPhaseColor.opacity(0.12))
        )
    }

    private func dueDateColor(_ date: Date) -> Color {
        if date < .now { return Color(red: 0.831, green: 0.298, blue: 0.278) } // overdue
        if date < .now.addingTimeInterval(86400) {
            return Color(red: 0.800, green: 0.569, blue: 0.180) // soon
        }
        return theme.textSecondary
    }

    // MARK: - Lower row (tags + assignees)

    private var hasLowerRow: Bool {
        !task.tags.isEmpty || sessionStore.count(for: task.id) > 0
    }

    @ViewBuilder
    private var lowerRow: some View {
        HStack(spacing: 8) {
            if !task.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(task.tags.enumerated()), id: \.offset) { _, tag in
                            Pill(
                                text: tag,
                                horizontalPadding: 8,
                                verticalPadding: 3
                            )
                        }
                    }
                }
            }
            PomodoroCountBadge(taskID: task.id)
            Spacer(minLength: 0)
        }
        .font(.system(size: 13))
    }
}

#Preview {
    @Previewable @Namespace var ns
    let item = WorkItem(
        title: "Add email field to the registration form with validation",
        priority: .medium,
        tags: ["UI", "Design", "Form"]
    )
    TaskCardView(task: item, namespace: ns)
        .padding(20)
        .frame(width: 340)
        .background(Color(red: 0.969, green: 0.969, blue: 0.969))
}
