//
//  ProjectDetailView.swift
//  TaskBar
//
//  Detail pane shown in the NavigationSplitView when a project is
//  selected. Composes the ProjectHeader, ProjectTabs, and the active
//  tab's content. Owns the tab selection.
//

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    let project: Project

    @Environment(\.theme) private var theme

    @State private var activeTab: ProjectTab = .board

    var body: some View {
        VStack(spacing: 0) {
            ProjectHeaderView(project: project)
            ProjectTabsView(selection: $activeTab)
            tabContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .board:
            BoardTab(project: project)
                .id(project.id) // reset internal @State when switching projects
        case .list:
            ListTab()
        case .activity:
            ActivityTab()
        case .files:
            FilesTab()
        }
    }
}

#Preview {
    let container = try! ModelContainerProvider.makeInMemoryContainer()
    let context = ModelContext(container)
    let projectRepo = ProjectRepository(context: context)
    let workRepo = WorkItemRepository(context: context)
    let project = try! projectRepo.create(
        name: "Website Redesign",
        colorHex: "#D49A6A",
        projectDescription: "Complete redesign of company website."
    )
    try! workRepo.create(title: "Product Redesign", status: .todo, priority: .medium, tags: ["UI", "Design"], project: project)
    try! workRepo.create(title: "Mobile App Beta", status: .doing, priority: .medium, tags: ["UI"], project: project)
    try! workRepo.create(title: "Performance Optimization", status: .doing, priority: .medium, tags: ["Performance"], project: project)
    try! workRepo.create(title: "API Integration for Tasks", status: .done, priority: .medium, tags: ["Backend"], project: project)
    return ProjectDetailView(project: project)
        .modelContainer(container)
        .environment(\.theme, .light)
        .frame(width: 1100, height: 720)
}
