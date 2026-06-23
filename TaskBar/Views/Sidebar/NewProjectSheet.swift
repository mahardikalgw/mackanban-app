//
//  NewProjectSheet.swift
//  TaskBar
//
//  Notion-style sheet for creating a project. Reads colors from \.theme.
//  Uses the shared `SheetActionBar` for the footer.
//

import SwiftUI

struct NewProjectSheet: View {
    let onSave: (String, String) -> Void
    let onCancel: () -> Void

    @Environment(\.theme) private var theme
    @State private var name: String = ""
    @State private var selectedColorHex: String = "#1A1A1A"

    private let palette: [String] = [
        "#1A1A1A",
        "#6B6B6B",
        "#A3A3A3",
        "#3A3A3A",
        "#525252",
        "#262626"
    ]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New project")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(theme.textPrimary)

            FormField(
                label: "Name",
                text: $name,
                placeholder: "Project name"
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("Color")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                HStack(spacing: 14) {
                    ForEach(palette, id: \.self) { hex in
                        Button {
                            selectedColorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .accentColor)
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColorHex == hex ? theme.textPrimary : .clear,
                                            lineWidth: 2
                                        )
                                        .padding(-3)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            SheetActionBar(
                primaryLabel: "Create",
                primaryDisabled: trimmedName.isEmpty,
                onPrimary: { onSave(trimmedName, selectedColorHex) },
                onCancel: onCancel
            )
        }
        .padding(28)
        .frame(width: 420)
        .background(theme.bg)
    }
}

#Preview {
    NewProjectSheet(onSave: { _, _ in }, onCancel: { })
        .environment(\.theme, .light)
}
