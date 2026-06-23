//
//  KanbanBoardView.swift
//  TaskBar
//
//  Four columns arranged horizontally. Each column fills its allocated
//  width AND the full available height so they stay perfectly parallel.
//  Stacks vertically below ~820pt for narrow displays.
//
//  Owns a shared `@Namespace` so cards can use `matchedGeometryEffect`
//  to animate smoothly between columns when their status changes.
//

import SwiftUI

struct KanbanBoardView: View {
    let grouped: [TaskStatus: [WorkItem]]
    var onTaskTap: ((UUID) -> Void)? = nil
    var onTaskDelete: ((UUID) -> Void)? = nil
    var onTaskDrop: ((UUID, TaskStatus) -> Void)? = nil
    var onQuickAdd: ((TaskStatus) -> Void)? = nil

    /// Shared namespace used by `matchedGeometryEffect` on each card so
    /// SwiftUI can interpolate a card's frame from its old column
    /// position to its new one when its status changes.
    @Namespace private var cardNamespace

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(TaskStatus.allCases) { status in
                    KanbanColumnView(
                        status: status,
                        tasks: grouped[status] ?? [],
                        namespace: cardNamespace,
                        onTaskTap: onTaskTap,
                        onTaskDelete: onTaskDelete,
                        onTaskDrop: onTaskDrop,
                        onQuickAdd: onQuickAdd
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            VStack(spacing: 16) {
                ForEach(TaskStatus.allCases) { status in
                    KanbanColumnView(
                        status: status,
                        tasks: grouped[status] ?? [],
                        namespace: cardNamespace,
                        onTaskTap: onTaskTap,
                        onTaskDelete: onTaskDelete,
                        onTaskDrop: onTaskDrop,
                        onQuickAdd: onQuickAdd
                    )
                }
            }
        }
    }
}

#Preview {
    let todo = WorkItem(title: "Wire up auth", priority: .high)
    let doing = WorkItem(title: "Fix bug", priority: .medium)
    let grouped: [TaskStatus: [WorkItem]] = [.todo: [todo], .doing: [doing], .done: []]
    KanbanBoardView(grouped: grouped, onQuickAdd: { _ in })
        .frame(width: 860, height: 540)
        .padding(16)
        .background(Color(red: 0.969, green: 0.969, blue: 0.969))
}
