//
//  AssigneeAvatarsView.swift
//  TaskBar
//
//  Overlapping circle avatars showing who is assigned to a task.
//  Renders initials in a deterministic warm color derived from the
//  member's name. Caps visible members and shows a "+N" counter.
//

import SwiftUI

struct AssigneeAvatarsView: View {
    let members: [TeamMember]
    var maxVisible: Int = 3
    var size: CGFloat = 22

    private var visible: [TeamMember] {
        Array(members.prefix(maxVisible))
    }

    private var overflowCount: Int {
        max(0, members.count - maxVisible)
    }

    var body: some View {
        if members.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: -overlap) {
                ForEach(visible, id: \.id) { member in
                    AvatarCircle(member: member, size: size)
                }
                if overflowCount > 0 {
                    OverflowCircle(count: overflowCount, size: size)
                }
            }
        }
    }

    /// How much each subsequent avatar overlaps the previous one.
    private var overlap: CGFloat {
        size * 0.32
    }
}

private struct AvatarCircle: View {
    let member: TeamMember
    let size: CGFloat

    @Environment(\.theme) private var theme

    var body: some View {
        Text(member.initials)
            .font(.system(size: size * 0.40, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                Circle().fill(member.color)
            )
            .overlay(
                Circle().strokeBorder(theme.cardBg, lineWidth: 1.5)
            )
            .help(member.displayName)
    }
}

private struct OverflowCircle: View {
    let count: Int
    let size: CGFloat

    @Environment(\.theme) private var theme

    var body: some View {
        Text("+\(count)")
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(theme.textSecondary)
            .frame(width: size, height: size)
            .background(
                Circle().fill(theme.tagBg)
            )
            .overlay(
                Circle().strokeBorder(theme.cardBg, lineWidth: 1.5)
            )
    }
}

#Preview {
    let members = [
        TeamMember(name: "Ava Chen"),
        TeamMember(name: "Leo Park"),
        TeamMember(name: "Mia Sato"),
        TeamMember(name: "Diego Rivera")
    ]
    return VStack(alignment: .leading, spacing: 12) {
        AssigneeAvatarsView(members: Array(members.prefix(1)))
        AssigneeAvatarsView(members: Array(members.prefix(2)))
        AssigneeAvatarsView(members: members)
    }
    .padding(20)
    .frame(width: 240)
    .background(Color.white)
}
