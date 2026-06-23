//
//  TaskDetailView.swift
//  TaskBar
//
//  Notion-style full editor. Reads colors from \.theme.
//  Surfaces assignees via AssigneePickerSheet.
//
//  Built from shared components: `FormField`, `FormTextEditor`,
//  `SheetActionBar`.
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    let task: WorkItem
    @Bindable var viewModel: TaskEditorViewModel
    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void

    @Environment(\.theme) private var theme
    @State private var showAssigneePicker: Bool = false

    init(
        task: WorkItem,
        repository: WorkItemRepository,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.task = task
        self.viewModel = TaskEditorViewModel(item: task, repository: repository)
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            FormField(label: "Title", text: $viewModel.title, placeholder: "Title")
            FormTextEditor(label: "Description", text: $viewModel.itemDescription)
            HStack(alignment: .top, spacing: 20) {
                priorityBlock
                dueDateBlock
            }
            FormField(
                label: "Tags (comma-separated)",
                text: $viewModel.tagsText,
                placeholder: "urgent, client"
            )
            assigneesBlock
            SheetActionBar(
                primaryLabel: "Save",
                primaryDisabled: !viewModel.canSave,
                leading: AnyView(deleteButton),
                onPrimary: saveAndClose,
                onCancel: onCancel
            )
        }
        .padding(28)
        .frame(width: 580)
        .background(theme.bg)
        .sheet(isPresented: $showAssigneePicker) {
            AssigneePickerSheet(
                viewModel: viewModel,
                onDone: { showAssigneePicker = false },
                onCancel: { showAssigneePicker = false }
            )
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Text(viewModel.existing == nil ? "New work item" : "Edit work item")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(theme.textPrimary)
            Spacer()
            if viewModel.existing != nil {
                startPomodoroButton
            }
        }
    }

    /// Small pill button in the header that starts a Pomodoro for the
    /// task being edited and brings up the floating timer window.
    private var startPomodoroButton: some View {
        Button {
            PomodoroTimer.shared.startWork(task: task)
            PomodoroWindowController.shared.show()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 12, weight: .semibold))
                Text("Start Pomodoro")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(theme.accentForeground)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(theme.accent)
            )
        }
        .buttonStyle(.plain)
        .help("Start a 25-minute Pomodoro for this task")
    }

    private var priorityBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
            PriorityPicker(priority: $viewModel.priority)
                .frame(width: 220)
        }
    }

    private var dueDateBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Due date")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
            HStack(spacing: 10) {
                Toggle("", isOn: dueDateEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                if viewModel.dueDate != nil {
                    DatePicker(
                        "Due",
                        selection: dueDateBinding,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .controlSize(.small)
                }
            }
        }
    }

    private var assigneesBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Assignees")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Button {
                    showAssigneePicker = true
                } label: {
                    Text(viewModel.assignees.isEmpty ? "Add" : "Edit")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
                .buttonStyle(.plain)
            }
            if viewModel.assignees.isEmpty {
                Text("No one assigned")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.textTertiary)
            } else {
                AssigneeAvatarsView(members: viewModel.assignees, maxVisible: 6, size: 26)
            }
        }
    }

    /// Destructive leading slot for SheetActionBar. Only present when
    /// editing an existing item.
    @ViewBuilder
    private var deleteButton: some View {
        if viewModel.existing != nil {
            Button("Delete", role: .destructive, action: onDelete)
                .font(.system(size: 15, weight: .semibold))
                .controlSize(.large)
        }
    }

    // MARK: - Helpers

    private var dueDateEnabled: Binding<Bool> {
        Binding(
            get: { viewModel.dueDate != nil },
            set: { isOn in
                viewModel.dueDate = isOn ? (viewModel.dueDate ?? .now) : nil
            }
        )
    }

    private var dueDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.dueDate ?? .now },
            set: { viewModel.dueDate = $0 }
        )
    }

    private func saveAndClose() {
        do {
            _ = try viewModel.save()
            onSave()
        } catch {
            print("TaskDetailView save failed: \(error)")
        }
    }
}
