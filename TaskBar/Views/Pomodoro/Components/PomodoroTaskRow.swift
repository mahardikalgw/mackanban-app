//
//  PomodoroTaskRow.swift
//  TaskBar
//
//  One row in the floating Pomodoro window's task picker. Tapping
//  starts a 25-minute work phase for the given task via the shared
//  `PomodoroTimer` and shows the floating window.
//
//

import SwiftUI

struct PomodoroTaskRow: View {
    let task: WorkItem
    let projectName: String?

    @State private var isHovering: Bool = false

    private var projectColor: Color {
        task.project?.color ?? .secondary
    }

    var body: some View {
        Button {
            PomodoroTimer.shared.startWork(task: task)
            PomodoroWindowController.shared.show()
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Circle()
                    .fill(task.priority.dotColor)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .strokeBorder(task.priority.dotColor.opacity(0.35), lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let projectName, !projectName.isEmpty {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(projectColor)
                                .frame(width: 6, height: 6)
                            Text(projectName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isHovering ? .primary : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovering ? Color.primary.opacity(0.06) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

#Preview {
    let task = WorkItem(title: "Wire up auth flow", priority: .high, tags: ["urgent"])
    return VStack(alignment: .leading, spacing: 4) {
        PomodoroTaskRow(task: task, projectName: "Website Redesign")
        PomodoroTaskRow(task: WorkItem(title: "Write spec doc", priority: .medium), projectName: "Mobile App")
        PomodoroTaskRow(task: WorkItem(title: "Read docs", priority: .low), projectName: nil)
    }
    .padding(12)
    .frame(width: 320)
    .background(Color(nsColor: .windowBackgroundColor))
}