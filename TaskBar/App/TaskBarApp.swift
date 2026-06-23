//
//  TaskBarApp.swift
//  TaskBar
//
//  @main entry. Hosts the WindowGroup that owns the NavigationSplitView
//  and installs the always-on-top Pomodoro window controller.
//

import SwiftUI
import SwiftData

@main
struct MackanbanApp: App {
    @State private var sidebarSelection: SidebarSelection = .dashboard

    var body: some Scene {
        WindowGroup {
            ContentRoot(selection: $sidebarSelection)
                .frame(
                    minWidth: 960,
                    idealWidth: 1180,
                    minHeight: 600,
                    idealHeight: 780
                )
        }
        .modelContainer(ModelContainerProvider.shared)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

/// Splits the content into sidebar + detail. Pulling this out of the
/// `App` body lets the sidebar binding live in `@State` without polluting
/// the `App` value type. Also wires the Pomodoro session-recording
/// observer (needs the model context, which the @App value doesn't have).
private struct ContentRoot: View {
    @Binding var selection: SidebarSelection

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .forward) private var projects: [Project]

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selection: $selection)
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            // Build the floating Pomodoro panel the first time the
            // root view appears (NSApplication is fully wired by then).
            PomodoroWindowController.shared.setupIfNeeded(context: modelContext)
            // Seed the demo data on first launch BEFORE reading
            // `projects` so the first-launch selection picks a real
            // project and the board has items to show.
            ModelContainerProvider.seedDefaultProjectIfNeeded(in: modelContext)
            // First-launch selection: pick the first project (the seeded
            // Website Redesign) so the user lands on a useful board.
            if case .dashboard = selection, let first = projects.first {
                selection = .project(first.id)
            }
            // Start recording completed Pomodoro work sessions.
            PomodoroSessionRecorder.shared.attach(context: modelContext)
            // Wire the per-task session-count cache so kanban cards
            // can show "🍅 N" badges reactively.
            PomodoroSessionStore.shared.attach(context: modelContext)
        }
        .onDisappear {
            PomodoroSessionRecorder.shared.detach()
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .dashboard:
            if let first = projects.first {
                ProjectDetailView(project: first)
            } else {
                EmptyDetailPlaceholder(
                    title: "No projects yet",
                    message: "Create a project from the sidebar to get started."
                )
            }
        case .project(let id):
            if let project = projects.first(where: { $0.id == id }) {
                ProjectDetailView(project: project)
            } else {
                EmptyDetailPlaceholder(
                    title: "Project not found",
                    message: "It may have been deleted. Pick another from the sidebar."
                )
            }
        }
    }
}

private struct EmptyDetailPlaceholder: View {
    let title: String
    let message: String

    var body: some View {
        PlaceholderView(
            icon: "tray",
            title: title,
            message: message,
            iconSize: 32
        )
    }
}

// MARK: - PomodoroSessionRecorder

/// Subscribes to `pomodoroWorkSessionCompleted` notifications and
/// writes each one to the SwiftData store via `PomodoroSessionRepository`.
/// Modeled as a separate object (rather than a closure inside
/// `ContentRoot`) so the observer lifetime is decoupled from view
/// identity, which can churn during hot-reload.
@MainActor
final class PomodoroSessionRecorder {
    static let shared = PomodoroSessionRecorder()
    private var observer: NSObjectProtocol?

    func attach(context: ModelContext) {
        detach()
        observer = NotificationCenter.default.addObserver(
            forName: .pomodoroWorkSessionCompleted,
            object: nil,
            queue: .main
        ) { note in
            guard let taskID = note.userInfo?["taskID"] as? UUID else { return }
            let repo = PomodoroSessionRepository(context: context)
            _ = try? repo.create(taskID: taskID)
        }
    }

    func detach() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }
}
