//
//  PlaceholderView.swift
//  TaskBar
//
//  Reusable empty / coming-soon state. Centered icon + title +
//  message. Used by the placeholder tabs (List / Activity /
//  Files) and the detail pane's fallback messages.
//

import SwiftUI

struct PlaceholderView: View {
    let icon: String
    let title: String
    let message: String
    var iconSize: CGFloat = 36

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .light))
                .foregroundStyle(theme.textTertiary)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.bg)
    }
}

#Preview {
    PlaceholderView(
        icon: "list.bullet.rectangle",
        title: "List view",
        message: "A flat list of every task in this project, sortable by priority or due date, is coming in a future update."
    )
    .environment(\.theme, .light)
    .frame(width: 800, height: 500)
}
