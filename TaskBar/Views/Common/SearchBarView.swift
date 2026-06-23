//
//  SearchBarView.swift
//  TaskBar
//
//  Notion-style search input. Reads colors from \.theme.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @Environment(\.theme) private var theme
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(theme.textSecondary)
            TextField("Search…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundStyle(theme.textPrimary)
                .focused($isFocused)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surfaceSubtle)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isFocused ? theme.textPrimary.opacity(0.55) : theme.border,
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    @Previewable @State var text = "fix bug"
    SearchBarView(text: $text)
        .padding()
        .frame(width: 360)
}
