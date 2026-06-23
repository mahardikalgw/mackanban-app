//
//  PomodoroWindowController.swift
//  TaskBar
//
//  Owns the always-on-top NSPanel that hosts the floating Pomodoro
//  timer window. The panel stays visible while the user works in
//  other apps and across fullscreen spaces.
//
//  Dynamically resizes based on the timer's phase: taller while
//  idle (to show the task picker) and compact while a phase is
//  running.
//
//  IMPORTANT: Panel creation is deferred until `show()` rather than
//  `setupIfNeeded()` because AppKit panel configuration can throw
//  Objective-C exceptions early in the view lifecycle.
//

import AppKit
import SwiftUI
import SwiftData

@MainActor
final class PomodoroWindowController {
    static let shared = PomodoroWindowController()

    /// The model context used by the task picker view. Set by
    /// `ContentRoot.task` before the panel is shown.
    var modelContext: ModelContext?

    private var panel: NSPanel?
    private var hostingController: NSHostingController<AnyView>?

    /// Idempotent: stores the model context. The actual NSPanel is
    /// lazily created on first `show()` because panel setup can throw
    /// ObjC exceptions if called too early in the view lifecycle.
    func setupIfNeeded(context: ModelContext?) {
        modelContext = context
        // Panel creation is deferred — see `lazyPanel()`.
    }

    /// Bring the timer window to the front. Creates the panel on
    /// first call.
    func show() {
        lazyPanel()
        guard let panel else { return }
        if panel.isVisible {
            panel.orderFrontRegardless()
        } else {
            panel.center()
            panel.makeKeyAndOrderFront(nil)
        }
    }

    func hide() {
        panel?.orderOut(nil)
    }

    /// Create the panel if it doesn't exist yet.
    private func lazyPanel() {
        guard panel == nil else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidthForCurrentPhase, height: panelHeightForCurrentPhase),
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .hudWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Focus Timer"
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isMovableByWindowBackground = true
        // Collection behavior: keep it minimal to avoid AppKit
        // validation exceptions (esp. when .hudWindow is used).
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.isRestorable = false

        let rootView = PomodoroTimerView()
        let host: NSHostingController<AnyView>
        if let modelContext {
            host = NSHostingController(
                rootView: AnyView(rootView.modelContext(modelContext))
            )
        } else {
            host = NSHostingController(rootView: AnyView(rootView))
        }
        panel.contentViewController = host
        self.panel = panel
        self.hostingController = host
    }

    /// Resize the panel to match the current timer phase.
    /// Called from `PomodoroTimerView.onChange(of: phase)`.
    func resizeToFitCurrentPhase() {
        guard let panel else { return }
        let newWidth = panelWidthForCurrentPhase
        let newHeight = panelHeightForCurrentPhase
        let currentFrame = panel.frame
        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.origin.y + (currentFrame.height - newHeight),
            width: newWidth,
            height: newHeight
        )
        panel.animator().setFrame(newFrame, display: true, animate: true)
    }

    // MARK: - Phase-based sizing

    private var panelWidthForCurrentPhase: CGFloat {
        switch PomodoroTimer.shared.phase {
        case .idle: return 340
        case .working, .finished: return 300
        }
    }

    private var panelHeightForCurrentPhase: CGFloat {
        switch PomodoroTimer.shared.phase {
        case .idle: return 460
        case .working: return 220
        case .finished: return 280
        }
    }
}
