//
//  KanbanColumnView.swift
//  TaskBar
//
//  Notion-style column: subtle surface, bold uppercase label,
//  generous spacing. Reads colors from \.theme so light/dark both work.
//
//  Owns no animation state of its own — the cross-column "move"
//  animation is driven by `matchedGeometryEffect` on each card,
//  threaded from `KanbanBoardView`'s shared namespace.
//

import SwiftUI

struct KanbanColumnView: View {
    let status: TaskStatus
    let tasks: [WorkItem]
    /// Shared namespace from `KanbanBoardView` so cards animate from
    /// their old column position to their new one when status changes.
    let namespace: Namespace.ID
    var onTaskTap: ((UUID) -> Void)? = nil
    var onTaskDelete: ((UUID) -> Void)? = nil
    var onTaskDrop: ((UUID, TaskStatus) -> Void)? = nil
    var onQuickAdd: ((TaskStatus) -> Void)? = nil

    @Environment(\.theme) private var theme
    @State private var isTargeted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(tasks, id: \.id) { task in
                        TaskCardView(task: task, namespace: namespace)
                            .onTapGesture { onTaskTap?(task.id) }
                            .contextMenu {
                                Button("Open") { onTaskTap?(task.id) }
                                Button("Start Pomodoro") {
                                    PomodoroTimer.shared.startWork(task: task)
                                    PomodoroWindowController.shared.show()
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    onTaskDelete?(task.id)
                                }
                            }
                    }
                    if tasks.isEmpty && !isTargeted {
                        emptyPlaceholder
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                // Animate insertion/removal/reordering within a column.
                // Cross-column motion is handled by matchedGeometryEffect.
                .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.85), value: tasks.map(\.id))
            }
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isTargeted ? theme.surfaceHover : theme.surfaceSubtle)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    isTargeted ? theme.accent.opacity(0.45) : theme.border,
                    lineWidth: isTargeted ? 1.5 : 1
                )
                .animation(.easeOut(duration: 0.12), value: isTargeted)
        )
        .dropDestination(for: String.self) { items, _ in
            guard let first = items.first,
                  let uuid = UUID(uuidString: first) else { return false }
            onTaskDrop?(uuid, status)
            return true
        } isTargeted: { isTargeted = $0 }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: status.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(status.dotColor)

            Text(status.headerLabel)
                .font(.system(size: 13, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)

            Spacer(minLength: 0)

            Text("\(tasks.count)")
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(theme.textTertiary)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    // MARK: - Footer (inline add)

    private var footer: some View {
        Button {
            onQuickAdd?(status)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                Text("Add task")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
    }

    // MARK: - Empty placeholder

    private var emptyPlaceholder: some View {
        Text("Empty")
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(theme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
    }
}

#Preview {
    @Previewable @Namespace var ns
    let todo = WorkItem(title: "Wire up auth flow", priority: .high, tags: ["urgent", "client"])
    let todo2 = WorkItem(title: "Write spec doc", priority: .medium)
    let todo3 = WorkItem(title: "Read docs on SwiftData", priority: .low)
    HStack(alignment: .top, spacing: 12) {
        KanbanColumnView(status: .todo, tasks: [todo, todo2, todo3], namespace: ns, onQuickAdd: { _ in })
        KanbanColumnView(status: .doing, tasks: [], namespace: ns, onQuickAdd: { _ in })
        KanbanColumnView(status: .done, tasks: [], namespace: ns, onQuickAdd: { _ in })
    }
    .padding(16)
    .frame(height: 480)
    .background(Color(red: 0.969, green: 0.969, blue: 0.969))
}
