//
//  PomodoroCountBadge.swift
//  TaskBar
//
//  Small pill showing how many completed Pomodoros are logged for a
//  task. Reads from `PomodoroSessionStore` so it updates live when a
//  work session finishes. Hidden when the count is zero.
//

import SwiftUI

struct PomodoroCountBadge: View {
    let taskID: UUID

    @Environment(\.theme) private var theme
    @State private var store = PomodoroSessionStore.shared

    private var count: Int { store.count(for: taskID) }

    var body: some View {
        if count > 0 {
            HStack(spacing: 3) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 7))
                Text("\(count)")
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(Color(red: 0.83, green: 0.30, blue: 0.28))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color(red: 0.83, green: 0.30, blue: 0.28).opacity(0.12))
            )
        }
    }
}
