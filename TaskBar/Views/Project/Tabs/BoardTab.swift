//
//  BoardTab.swift
//  TaskBar
//
//  Active tab content for `ProjectTab.board`. Wraps the kanban board
//  view and wires the project-level ViewModel to it.
//

import SwiftUI
import SwiftData

struct BoardTab: View {
    let project: Project

    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme

    @State private var viewModel: KanbanViewModel?
    @State private var searchText: String = ""
    @State private var showQuickAdd: Bool = false
    @State private var editingItemID: UUID?

    var body: some View {
        Group {
            if let viewModel {
                KanbanBoardView(
                    grouped: viewModel.groupedItems,
                    onTaskTap: { id in editingItemID = id },
                    onTaskDelete: { id in viewModel.delete(itemID: id) },
                    onTaskDrop: { id, newStatus in viewModel.move(itemID: id, to: newStatus) },
                    onQuickAdd: { _ in showQuickAdd = true }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 24)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(theme.bg)
        .task {
            if viewModel == nil {
                let repo = WorkItemRepository(context: modelContext)
                viewModel = KanbanViewModel(repository: repo)
            }
            viewModel?.selectedProject = project
            // Wire search text into the view model reactively.
            viewModel?.searchText = searchText
        }
        .onChange(of: searchText) { _, newValue in
            viewModel?.searchText = newValue
        }
        .onChange(of: project.id) { _, _ in
            viewModel?.selectedProject = project
        }
        .sheet(isPresented: $showQuickAdd) {
            let repo = WorkItemRepository(context: modelContext)
            QuickAddView(
                viewModel: QuickAddViewModel(repository: repo, defaultProject: project),
                onSaved: {
                    viewModel?.reload()
                    showQuickAdd = false
                },
                onCancel: { showQuickAdd = false }
            )
        }
        .sheet(item: editingItemBinding) { id in
            if let item = viewModel?.items.first(where: { $0.id == id }) {
                TaskDetailView(
                    task: item,
                    repository: WorkItemRepository(context: modelContext),
                    onSave: {
                        viewModel?.reload()
                        editingItemID = nil
                    },
                    onCancel: { editingItemID = nil },
                    onDelete: {
                        viewModel?.delete(itemID: id)
                        editingItemID = nil
                    }
                )
            }
        }
        .background(
            Button("") { showQuickAdd = true }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        )
    }

    /// External callers (the top bar) bind to this to wire their search field.
    var searchTextBinding: Binding<String> {
        Binding(get: { searchText }, set: { searchText = $0 })
    }

    private var editingItemBinding: Binding<UUID?> {
        Binding(get: { editingItemID }, set: { editingItemID = $0 })
    }
}

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

#Preview {
    let container = try! ModelContainerProvider.makeInMemoryContainer()
    let context = ModelContext(container)
    let projectRepo = ProjectRepository(context: context)
    let workRepo = WorkItemRepository(context: context)
    let project = try! projectRepo.create(name: "Website Redesign", projectDescription: "Complete redesign of company website.")
    try! workRepo.create(title: "Product Redesign", status: .todo, priority: .medium, tags: ["UI"], project: project)
    try! workRepo.create(title: "Mobile App Beta", status: .doing, priority: .medium, tags: ["UI"], project: project)
    try! workRepo.create(title: "API Integration", status: .done, priority: .medium, tags: ["Backend"], project: project)
    return BoardTab(project: project)
        .modelContainer(container)
        .environment(\.theme, .light)
        .frame(width: 1000, height: 600)
}
