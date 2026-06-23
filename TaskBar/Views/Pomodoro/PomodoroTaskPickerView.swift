//
//  PomodoroTaskPickerView.swift
//  TaskBar
//
//  Task picker shown inside the floating Pomodoro window when the
//  timer is idle. The user picks a task to focus on, which starts
//  a 25-minute work phase and switches the panel to the active
//  timer layout.
//
//  Shows tasks from `PomodoroTimer.shared.currentProjectID` when
//  available, falling back to all projects grouped. A compact text
//  field lets the user filter tasks by title.
//
//

import SwiftUI
import SwiftData

struct PomodoroTaskPickerView: View {
    @State private var filterText: String = ""

    /// Loaded on appear from the window controller's stored context.
    @State private var tasks: [WorkItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if !filteredTasks.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredTasks, id: \.id) { task in
                            PomodoroTaskRow(
                                task: task,
                                projectName: task.project?.name
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            } else {
                emptyState
            }
        }
        .onAppear {
            loadTasks()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick a task to focus on")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Filter tasks…", text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.06))
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Filtered tasks

    private var filteredTasks: [WorkItem] {
        let result: [WorkItem]
        if filterText.trimmingCharacters(in: .whitespaces).isEmpty {
            result = tasks
        } else {
            let query = filterText.lowercased()
            result = tasks.filter { $0.title.lowercased().contains(query) }
        }
        // Sort: active project's tasks first, then by priority
        let activeProjectID = PomodoroTimer.shared.currentProjectID
        return result.sorted { a, b in
            let aIsActive = a.project?.id == activeProjectID
            let bIsActive = b.project?.id == activeProjectID
            if aIsActive != bIsActive { return aIsActive }
            return a.priority.sortWeight < b.priority.sortWeight
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text(filterText.isEmpty ? "No tasks yet" : "No tasks match")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            if !filterText.isEmpty {
                Text("Try a different search term.")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Load

    private func loadTasks() {
        guard let context = PomodoroWindowController.shared.modelContext else {
            tasks = []
            return
        }
        do {
            let descriptor = FetchDescriptor<WorkItem>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            tasks = try context.fetch(descriptor)
        } catch {
            tasks = []
        }
    }
}

#Preview {
    PomodoroTaskPickerView()
        .frame(width: 320, height: 440)
        .background(Color(nsColor: .windowBackgroundColor))
}
