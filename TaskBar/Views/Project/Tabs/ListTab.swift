//
//  ListTab.swift
//  TaskBar
//
//  Placeholder tab content for `ProjectTab.list`. Uses the shared
//  `PlaceholderView` for the empty state.
//

import SwiftUI

struct ListTab: View {
    var body: some View {
        PlaceholderView(
            icon: "list.bullet.rectangle",
            title: "List view",
            message: "A flat list of every task in this project, sortable by priority or due date, is coming in a future update."
        )
    }
}

#Preview {
    ListTab()
        .environment(\.theme, .light)
        .frame(width: 1000, height: 600)
}
