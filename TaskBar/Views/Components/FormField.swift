//
//  FormField.swift
//  TaskBar
//
//  Reusable labeled single-line text input. Used across every
//  sheet that needs a "Title" / "Tags" / etc. field. Provides
//  consistent label typography, padding, and surface treatment.
//

import SwiftUI

struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var onSubmit: (() -> Void)? = nil

    @Environment(\.theme) private var theme
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .padding(12)
                .background(surface)
                .focused($isFocused)
                .onSubmit { onSubmit?() }
        }
    }

    private var surface: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(theme.fieldBg)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.border, lineWidth: 1)
            )
    }
}

// MARK: - Multi-line variant

struct FormTextEditor: View {
    let label: String
    @Binding var text: String
    var minHeight: CGFloat = 110
    var maxHeight: CGFloat = 180

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
            TextEditor(text: $text)
                .font(.system(size: 16))
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: minHeight, maxHeight: maxHeight)
                .background(surface)
        }
    }

    private var surface: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(theme.fieldBg)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.border, lineWidth: 1)
            )
    }
}

#Preview {
    @Previewable @State var title: String = "Wire up auth flow"
    @Previewable @State var description: String = "Connect the email field to the registration API."
    return VStack(alignment: .leading, spacing: 20) {
        FormField(label: "Title", text: $title, placeholder: "What needs doing?")
        FormTextEditor(label: "Description", text: $description)
    }
    .padding(28)
    .frame(width: 480)
    .background(Color(red: 0.980, green: 0.969, blue: 0.949))
}
