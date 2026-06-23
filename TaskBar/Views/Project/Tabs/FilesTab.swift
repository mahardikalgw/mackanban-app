//
//  FilesTab.swift
//  TaskBar
//
//  Placeholder tab content for `ProjectTab.files`. Uses the shared
//  `PlaceholderView` for the empty state.
//

import SwiftUI

struct FilesTab: View {
    var body: some View {
        PlaceholderView(
            icon: "folder",
            title: "Files",
            message: "Project file attachments will land in a future update."
        )
    }
}

#Preview {
    FilesTab()
        .environment(\.theme, .light)
        .frame(width: 1000, height: 600)
}
