//
//  Pill.swift
//  TaskBar
//
//  Reusable capsule badge — the small text + optional icon/dot
//  pill used across the app for priority badges, due-date pills,
//  tag chips, and any other compact label that needs a soft
//  surface to sit on.
//
//  Reads colors from \.theme so light/dark both work.
//

import SwiftUI

struct Pill: View {
    let text: String
    var icon: String? = nil
    var dotColor: Color? = nil
    var foreground: Color? = nil
    var background: Color? = nil
    var iconSize: CGFloat = 11
    var textSize: CGFloat = 11
    var horizontalPadding: CGFloat = 10
    var verticalPadding: CGFloat = 5
    var textWeight: Font.Weight = .semibold

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 5) {
            if let dotColor {
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
            }
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .semibold))
            }
            Text(text)
                .font(.system(size: textSize, weight: textWeight))
                .tracking(0.3)
        }
        .foregroundStyle(foreground ?? theme.textSecondary)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            Capsule().fill(background ?? theme.tagBg)
        )
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        Pill(text: "Medium", dotColor: .orange)
        Pill(text: "Aug 5", icon: "calendar")
        Pill(text: "UI")
        Pill(text: "Done", icon: "checkmark.circle.fill")
        Pill(text: "5 comments", icon: "bubble.left", background: .blue.opacity(0.15))
    }
    .padding(20)
    .background(Color.white)
}
