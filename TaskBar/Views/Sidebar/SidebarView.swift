//
//  SidebarView.swift
//  TaskBar
//
//  Left navigation rail inside the NavigationSplitView. Shows the
//  app brand, the Dashboard entry, and the projects list.
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selection: SidebarSelection

    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Project.createdAt, order: .forward) private var projects: [Project]

    @State private var showNewProject: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    sectionHeader("Workspace")
                    navRow(.dashboard, label: "Dashboard", icon: "house")

                    projectsSection
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
            }
        }
        .frame(minWidth: 240)
        .background(sidebarBackground)
        .sheet(isPresented: $showNewProject) {
            NewProjectSheet(
                onSave: handleNewProject,
                onCancel: { showNewProject = false }
            )
        }
    }

    // MARK: - Brand

    private var brandHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.accent)
                    .frame(width: 28, height: 28)
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.accentForeground)
            }
            Text("Mackanban")
                .font(.system(size: 16, weight: .bold))
                .tracking(-0.2)
                .foregroundStyle(theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
    }

    // MARK: - Projects section

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                sectionHeader("Projects")
                Spacer()
                Button {
                    showNewProject = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("New project")
            }
            .padding(.horizontal, 0)
            .padding(.top, 12)
            .padding(.bottom, 4)

            if projects.isEmpty {
                Text("No projects yet")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            } else {
                ForEach(projects, id: \.id) { project in
                    projectRow(project)
                }
            }
        }
    }

    private func projectRow(_ project: Project) -> some View {
        let isSelected = selection == .project(project.id)
        return Button {
            selection = .project(project.id)
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(project.color)
                    .frame(width: 10, height: 10)
                Text(project.name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? theme.surfaceHover : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .heavy))
            .tracking(0.8)
            .foregroundStyle(theme.textTertiary)
            .padding(.horizontal, 10)
            .padding(.top, 12)
            .padding(.bottom, 6)
    }

    @ViewBuilder
    private func navRow(_ value: SidebarSelection, label: String, icon: String) -> some View {
        let isSelected = selection == value
        Button {
            selection = value
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 18)
                    .foregroundStyle(isSelected ? theme.accent : theme.textSecondary)
                Text(label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? theme.surfaceHover : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Glass-tinted sidebar background. Real `.ultraThinMaterial` would
    /// need content underneath; we approximate with a warm white tint
    /// over the window's bg so the sidebar reads as a layered surface.
    private var sidebarBackground: some View {
        ZStack {
            theme.surfaceSubtle
            LinearGradient(
                colors: [
                    Color.white.opacity(0.30),
                    Color.white.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        }
        .ignoresSafeArea()
    }

    private func handleNewProject(name: String, hex: String) {
        let repo = ProjectRepository(context: modelContext)
        guard let project = try? repo.create(name: name, colorHex: hex) else {
            showNewProject = false
            return
        }
        showNewProject = false
        selection = .project(project.id)
    }
}

/// What the sidebar can select. `.dashboard` is the top-level entry;
/// `.project(...)` opens a specific project.
enum SidebarSelection: Hashable {
    case dashboard
    case project(UUID)
}

#Preview {
    @Previewable @State var selection: SidebarSelection = .dashboard
    let container = try! ModelContainerProvider.makeInMemoryContainer()
    let context = ModelContext(container)
    let projectRepo = ProjectRepository(context: context)
    _ = try? projectRepo.create(name: "Website Redesign", colorHex: "#D49A6A", projectDescription: "Complete redesign of company website.")
    _ = try? projectRepo.create(name: "Mobile App", colorHex: "#5A7A8C")
    return SidebarView(selection: $selection)
        .modelContainer(container)
        .environment(\.theme, .light)
        .frame(width: 260, height: 640)
}
