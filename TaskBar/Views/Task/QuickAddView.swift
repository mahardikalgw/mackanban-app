//
//  QuickAddView.swift
//  TaskBar
//
//  Notion-style quick-add popup. Built from shared components:
//  `FormField`, `FormTextEditor`, `SheetActionBar`.
//

import SwiftUI

struct QuickAddView: View {
    @Bindable var viewModel: QuickAddViewModel
    let onSaved: () -> Void
    let onCancel: () -> Void

    @Environment(\.theme) private var theme
    @FocusState private var titleFocused: Bool

    private var trimmedTitle: String {
        viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New task")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(theme.textPrimary)

            FormField(
                label: "Title",
                text: $viewModel.title,
                placeholder: "What needs doing?",
                onSubmit: trySave
            )
            .focused($titleFocused)

            FormTextEditor(label: "Description", text: $viewModel.itemDescription)

            SheetActionBar(
                primaryLabel: "Save",
                primaryDisabled: trimmedTitle.isEmpty,
                onPrimary: trySave,
                onCancel: onCancel
            )
        }
        .padding(28)
        .frame(width: 460)
        .background(theme.bg)
        .onAppear { titleFocused = true }
    }

    private func trySave() {
        guard !trimmedTitle.isEmpty else { return }
        do {
            _ = try viewModel.save()
            viewModel.reset()
            onSaved()
        } catch {
            print("QuickAddView save failed: \(error)")
        }
    }
}

#Preview {
    let context = try! ModelContainerProvider.makeInMemoryContainer().mainContext
    QuickAddView(
        viewModel: QuickAddViewModel(repository: WorkItemRepository(context: context)),
        onSaved: {},
        onCancel: {}
    )
}
