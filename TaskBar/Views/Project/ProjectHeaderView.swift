//
//  ProjectHeaderView.swift
//  TaskBar
//
//  Project title + description shown above the tab navigation.
//

import SwiftUI
import SwiftData

struct ProjectHeaderView: View {
    let project: Project

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Circle()
                    .fill(project.color)
                    .frame(width: 10, height: 10)
                Text(project.name)
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                pomodoroButton
            }
            if !project.projectDescription.isEmpty {
                Text(project.projectDescription)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Pomodoro button

    private var pomodoroButton: some View {
        Button {
            PomodoroWindowController.shared.show()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .semibold))
                Text("Pomodoro")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(theme.accentForeground)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.accent)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let container = try! ModelContainerProvider.makeInMemoryContainer()
    let context = ModelContext(container)
    let repo = ProjectRepository(context: context)
    let project = try! repo.create(
        name: "Website Redesign",
        colorHex: "#D49A6A",
        projectDescription: "Complete redesign of company website."
    )
    ProjectHeaderView(project: project)
        .environment(\.theme, .light)
        .frame(width: 1000)
        .background(Color(red: 0.980, green: 0.969, blue: 0.949))
}
