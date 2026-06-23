//
//  AssigneePickerSheet.swift
//  TaskBar
//
//  Sheet that lets the user toggle team-member assignments for a task.
//  Uses the shared `SheetActionBar` for the footer.
//

import SwiftUI
import SwiftData

struct AssigneePickerSheet: View {
    @Bindable var viewModel: TaskEditorViewModel
    let onDone: () -> Void
    let onCancel: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TeamMember.createdAt, order: .forward) private var allMembers: [TeamMember]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assignees")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(theme.textPrimary)

            if allMembers.isEmpty {
                Text("No team members yet. Add members in the Team section.")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.textSecondary)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(allMembers, id: \.id) { member in
                            row(for: member)
                        }
                    }
                }
                .frame(maxHeight: 280)
            }

            SheetActionBar(
                primaryLabel: "Done",
                onPrimary: onDone,
                onCancel: onCancel
            )
        }
        .padding(28)
        .frame(width: 420)
        .background(theme.bg)
    }

    private func row(for member: TeamMember) -> some View {
        let isSelected = viewModel.assignees.contains { $0.id == member.id }
        return Button {
            toggle(member)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(member.color)
                        .frame(width: 28, height: 28)
                    Text(member.initials)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.textPrimary)
                    if let role = member.role, !role.isEmpty {
                        Text(role)
                            .font(.system(size: 12))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? theme.accent : theme.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? theme.surfaceHover : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ member: TeamMember) {
        if let idx = viewModel.assignees.firstIndex(where: { $0.id == member.id }) {
            viewModel.assignees.remove(at: idx)
        } else {
            viewModel.assignees.append(member)
        }
    }
}
