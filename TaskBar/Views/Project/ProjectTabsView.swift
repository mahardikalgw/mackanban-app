//
//  ProjectTabsView.swift
//  TaskBar
//
//  Pill-style tab navigation (Board / List / Activity / Files).
//  Active tab is filled with the accent color; inactive tabs are
//  text-only. Single-selection; the parent owns the selection.
//

import SwiftUI

enum ProjectTab: String, CaseIterable, Identifiable, Hashable {
    case board
    case list
    case activity
    case files

    var id: String { rawValue }

    var label: String {
        switch self {
        case .board: "Board"
        case .list: "List"
        case .activity: "Activity"
        case .files: "Files"
        }
    }
}

struct ProjectTabsView: View {
    @Binding var selection: ProjectTab

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ProjectTab.allCases) { tab in
                pill(for: tab)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 14)
    }

    private func pill(for tab: ProjectTab) -> some View {
        let isSelected = selection == tab
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                selection = tab
            }
        } label: {
            Text(tab.label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? theme.accentForeground : theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(isSelected ? theme.accent : Color.clear)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selection: ProjectTab = .board
    return ProjectTabsView(selection: $selection)
        .environment(\.theme, .light)
        .frame(width: 1000)
        .padding(.vertical, 8)
        .background(Color(red: 0.980, green: 0.969, blue: 0.949))
}
