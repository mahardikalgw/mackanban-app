//
//  PriorityPicker.swift
//  TaskBar
//
//  Segmented picker for the three priority levels.
//

import SwiftUI

struct PriorityPicker: View {
    @Binding var priority: Priority

    var body: some View {
        Picker("Priority", selection: $priority) {
            ForEach(Priority.allCases) { p in
                Text(p.displayName).tag(p)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}
