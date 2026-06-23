//
//  PomodoroWindowController.swift
//  Mackanban
//
//  Manages the Pomodoro timer's menu bar presence and popover.
//
//  When the timer is idle the menu bar icon shows "🍅". When a
//  work phase is running the icon shows the remaining time.
//  Clicking the icon opens/closes a popover with the full
//  PomodoroTimerView (drop zone, duration picker, countdown,
//  finished controls).
//
//  The popover closes without stopping the timer — the user can
//  keep working while the countdown runs in the menu bar.
//

import AppKit
import SwiftUI
import SwiftData

@MainActor
final class PomodoroWindowController {
    static let shared = PomodoroWindowController()

    var modelContext: ModelContext?

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var hostingController: NSHostingController<AnyView>?
    private var ticker: Timer?

    // MARK: - Setup

    func setupIfNeeded(context: ModelContext?) {
        modelContext = context
        // Create the status item immediately so it's in the menu bar
        // and positioned before the user first opens the popover.
        createStatusItem()
        createPopover()
        startMenuBarTicker()
    }

    /// Show the popover at the status item's position.
    func show() {
        guard let popover, let statusItem else { return }
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        // Force the popover to appear; transient behaviour on first
        // show can be unreliable if the status item window is not
        // yet fully positioned.
        if let popoverWindow = popover.contentViewController?.view.window {
            popoverWindow.orderFrontRegardless()
        }
    }

    func hide() {
        popover?.performClose(nil)
    }

    // MARK: - Status item

    private func createStatusItem() {
        let item = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        item.button?.title = "🍅"
        item.button?.action = #selector(togglePopover)
        item.button?.target = self
        statusItem = item
    }

    private func createPopover() {
        let p = NSPopover()
        p.behavior = .transient
        p.animates = true

        let rootView = PomodoroTimerView()
        let host: NSHostingController<AnyView>
        if let modelContext {
            host = NSHostingController(
                rootView: AnyView(rootView.modelContext(modelContext))
            )
        } else {
            host = NSHostingController(rootView: AnyView(rootView))
        }
        p.contentViewController = host
        p.contentSize = currentPopoverSize

        hostingController = host
        popover = p
    }

    // MARK: - Menu bar ticker

    private func startMenuBarTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItemTitle()
            }
        }
    }

    private func updateStatusItemTitle() {
        let title: String
        switch PomodoroTimer.shared.phase {
        case .idle:
            title = "🍅"
        case .working:
            let remaining = PomodoroTimer.shared.secondsRemaining()
            let m = remaining / 60
            let s = remaining % 60
            title = "🍅 \(String(format: "%02d:%02d", m, s))"
        case .finished:
            title = "🍅 DONE"
        }
        statusItem?.button?.title = title
    }

    // MARK: - Popover toggle

    @objc private func togglePopover() {
        guard let popover, let statusItem else { return }
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
        }
    }

    // MARK: - Resize

    func resizeToFitCurrentPhase() {
        guard let popover else { return }
        popover.contentSize = currentPopoverSize
        if popover.isShown, let button = statusItem?.button {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
        }
    }

    private var currentPopoverSize: NSSize {
        switch PomodoroTimer.shared.phase {
        case .idle:    return NSSize(width: 340, height: 460)
        case .working: return NSSize(width: 300, height: 220)
        case .finished: return NSSize(width: 300, height: 280)
        }
    }

    deinit {
        ticker?.invalidate()
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
    }
}
