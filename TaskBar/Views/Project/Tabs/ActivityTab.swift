//
//  ActivityTab.swift
//  TaskBar
//
//  Placeholder tab content for `ProjectTab.activity`. Uses the shared
//  `PlaceholderView` for the empty state.
//

import SwiftUI

struct ActivityTab: View {
    var body: some View {
        PlaceholderView(
            icon: "clock.arrow.circlepath",
            title: "Activity",
            message: "An audit log of status changes and edits will land in a future update."
        )
    }
}

#Preview {
    ActivityTab()
        .environment(\.theme, .light)
        .frame(width: 1000, height: 600)
}
