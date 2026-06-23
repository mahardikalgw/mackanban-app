//
//  SheetActionBar.swift
//  TaskBar
//
//  Reusable footer row for every sheet: Cancel + Primary button,
//  with an optional destructive leading slot (e.g. Delete) on
//  the left. Wires up the standard keyboard shortcuts (Esc and
//  Return) so callers don't have to.
//

import SwiftUI

struct SheetActionBar: View {
    let cancelLabel: String
    let primaryLabel: String
    var primaryDisabled: Bool = false
    var leading: AnyView?
    let onPrimary: () -> Void
    let onCancel: () -> Void

    @Environment(\.theme) private var theme

    init(
        cancelLabel: String = "Cancel",
        primaryLabel: String,
        primaryDisabled: Bool = false,
        leading: AnyView? = nil,
        onPrimary: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.cancelLabel = cancelLabel
        self.primaryLabel = primaryLabel
        self.primaryDisabled = primaryDisabled
        self.leading = leading
        self.onPrimary = onPrimary
        self.onCancel = onCancel
    }

    var body: some View {
        HStack(spacing: 12) {
            if let leading { leading }
            Spacer()
            Button(cancelLabel, action: onCancel)
                .keyboardShortcut(.cancelAction)
                .font(.system(size: 15, weight: .semibold))
                .controlSize(.large)
            Button(primaryLabel, action: onPrimary)
                .keyboardShortcut(.defaultAction)
                .disabled(primaryDisabled)
                .font(.system(size: 15, weight: .semibold))
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .controlSize(.large)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        SheetActionBar(
            primaryLabel: "Save",
            onPrimary: {},
            onCancel: {}
        )
        SheetActionBar(
            primaryLabel: "Create",
            primaryDisabled: true,
            leading: AnyView(
                Button("Delete", role: .destructive) {}
                    .font(.system(size: 15, weight: .semibold))
                    .controlSize(.large)
            ),
            onPrimary: {},
            onCancel: {}
        )
    }
    .padding(28)
    .frame(width: 540)
    .background(Color(red: 0.980, green: 0.969, blue: 0.949))
}
