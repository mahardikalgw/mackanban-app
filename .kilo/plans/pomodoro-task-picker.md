# Pomodoro Task Picker Feature

## Goal

Let the user **pick a task and run it in the Pomodoro timer** from anywhere in the app — both from the kanban board and from the floating timer window itself — and give the user clear visual feedback while a Pomodoro is in progress.

## Context (current state)

A working Pomodoro state machine, floating window, and persistence layer already exist:

- `Models/PomodoroSession.swift` — `@Model` entity storing one completed work session (`taskID`, `completedAt`, `durationSeconds`).
- `Persistence/PomodoroSessionRepository.swift` — CRUD (`create`, `count(taskID:)`, `fetchAll(for:)`, `deleteAll`).
- `ViewModels/PomodoroTimer.swift` — `@Observable` singleton with `phase: .idle | .work(taskID:) | .shortBreak`, `startWork(task:)`, `pause/resume/reset/skip`, posts `.pomodoroWorkSessionCompleted` on natural work completion.
- `App/PomodoroWindowController.swift` — floating `NSPanel` (.floating, .utilityWindow, .hudWindow, .nonactivatingPanel, .canJoinAllSpaces, .fullScreenAuxiliary).
- `Views/Pomodoro/PomodoroTimerView.swift` — UI of the floating window: phase badge, big timer, task title, progress bar, play/pause/reset/skip.
- `App/TaskBarApp.swift` — `PomodoroSessionRecorder` listens for the completion notification and persists a `PomodoroSession` via the repository.
- `Views/Task/TaskDetailView.swift` — "Start Pomodoro" button in the detail header (only existing way to start a phase).

## What's missing vs. the request

| # | Gap | User impact |
|---|-----|-------------|
| 1 | The user can only start a Pomodoro from the task detail view. | Has to open the sheet for every card — slow. |
| 2 | The floating window has no task picker when idle. | When the timer is "READY", the user can't choose what to work on without going back to the app. |
| 3 | The card has no "active focus" indicator while its task is the current Pomodoro. | Can't see at a glance which task is being worked on. |
| 4 | The card has no completed-Pomodoro count. | No per-task history of focus time. |
| 5 | No way to switch the active task mid-session from the floating window. | Painful to redirect focus to a different task. |

## Approach (high level)

Wire the existing primitives into the kanban card and the floating window, and add a tiny "switch task" sheet inside the floating window. No new model entities, no schema changes. The persistence layer and state machine are reused as-is.

```
                ┌──────────────────────────────────────────────────┐
                │            Floating PomodoroWindow                │
                │  idle  → "Pick a task" picker                     │
                │  work  → current task + [Switch task] button      │
                │  break → [Skip to next work] button               │
                └──────────────────────────────────────────────────┘
                              ▲                  ▲
            start from card   │                  │  start from detail
                              │                  │
   ┌──────────────────────────┴──┐         ┌─────┴──────────────────┐
   │  TaskCardView                │         │  TaskDetailView         │
   │  + [▶] quick-start button    │         │  + "Start Pomodoro"     │
   │  + 🍅 count badge            │         │    (already there)      │
   │  + active-focus ring         │         │                         │
   └──────────────────────────────┘         └─────────────────────────┘
```

## Chunks

### Chunk 1 — Make the floating window pickable when idle

**Why first**: this is the heart of the user's request. Once the user can pick a task from the window itself, the rest is polish.

**Scope**:
- New `Views/Pomodoro/PomodoroTaskPickerView.swift` — a compact list of tasks the user can pick from. Lives inside the floating panel. Shows tasks from the current project (resolved via the most-recently-active `PomodoroTimer`-tracked project ID, or all projects as a fallback). Each row: priority dot + title + project name. Filterable by a small text field.
- New `Views/Pomodoro/Components/PomodoroTaskRow.swift` — one row in the picker. Calls `PomodoroTimer.shared.startWork(task:)` and dismisses the picker on tap.
- `PomodoroWindowController` — resize the panel to ~320×440 while idle so the picker fits. Restore to ~300×200 when a phase is active.
- `PomodoroTimerView` — restructure into a 2-state body:
  - `.idle` → show `PomodoroTaskPickerView` (no big timer, no play/reset/skip).
  - `.work / .shortBreak` → show the existing layout (big timer, controls).
  - A small "Switch task" link in the work/break layout that toggles a sheet for picking a different task mid-phase (confirms if a work phase is running).
- `PomodoroTimer` — add `currentProjectID` published state. The picker reads it. Set it whenever `startWork(task:)` is called.

**Files**:
- `TaskBar/Views/Pomodoro/PomodoroTimerView.swift` (modify).
- `TaskBar/Views/Pomodoro/PomodoroTaskPickerView.swift` (new).
- `TaskBar/Views/Pomodoro/Components/PomodoroTaskRow.swift` (new).
- `TaskBar/ViewModels/PomodoroTimer.swift` (add `currentProjectID`).
- `TaskBar/App/PomodoroWindowController.swift` (resize on phase change).

**Accept when**:
1. With the app launched, clicking the menu bar (no Pomodoro running) shows the floating window in picker mode.
2. The picker lists all tasks for the current project. Typing in the filter field narrows the list.
3. Tapping a row starts a 25-min work phase, sets the floating window to work mode, and the card in the kanban shows the active-focus indicator.
4. Tapping the same row again does not create a duplicate session.
5. Quitting and relaunching the app — the picker still works.

### Chunk 2 — Quick-start from the kanban card

**Why second**: gives the user a one-click path to start a Pomodoro without opening detail.

**Scope**:
- `TaskCardView` — add a small "▶" button in the top-right of the card (next to the due-date pill, or as a hover-revealed overlay on the card). Tapping it calls `PomodoroTimer.shared.startWork(task: task)` and `PomodoroWindowController.shared.show()`.
- `PomodoroTimer.startWork(task:)` — guard against starting when the same task is already the active work task (no-op) so the user can't double-fire.
- Context menu on the card — add a "Start Pomodoro" entry alongside the existing "Open" / "Delete" entries.

**Files**:
- `TaskBar/Views/Kanban/TaskCardView.swift` (modify — add start button + context menu entry).
- `TaskBar/Views/Kanban/KanbanColumnView.swift` (modify — add context menu entry).
- `TaskBar/ViewModels/PomodoroTimer.swift` (modify — add no-op guard).

**Accept when**:
1. Hovering a card reveals a small play icon in the top-right.
2. Clicking the play icon starts a Pomodoro for that task and brings the floating window to the front.
3. The card in the kanban visually indicates it is the active task.
4. Right-clicking a card and choosing "Start Pomodoro" has the same effect.
5. Clicking play on the already-active card does nothing (no phase restart, no extra session).

### Chunk 3 — Active-focus indicator on the kanban card

**Why third**: visual feedback that ties the floating timer to the card.

**Scope**:
- `TaskCardView` — observe `PomodoroTimer.shared` via `@State` (or accept the timer as a parameter). When `timer.isActiveTask(taskID: task.id)` is true, render:
  - A subtle "Focus" pill in the top-right meta row (tomato/red color, `timer` SF Symbol).
  - A coloured left-edge accent (4pt wide) matching the work phase.
- `TaskCardView` — pulse the focus pill gently (0.6Hz opacity oscillation) while a work phase is active for that task.

**Files**:
- `TaskBar/Views/Kanban/TaskCardView.swift` (modify — add focus indicator).

**Accept when**:
1. When a Pomodoro is running for task A, the card for A shows a "Focus" pill and a coloured left edge.
2. When the same Pomodoro is paused, the pill stays (paused, not gone).
3. When the phase advances to short break, the pill disappears from A.
4. When the user starts a Pomodoro for task B, A's pill disappears and B's pill appears.
5. During a drag of the active card the indicator is still visible (no flicker).

### Chunk 4 — Per-task completed-Pomodoro count on the card

**Why fourth**: gives the user a sense of accumulated focus per task and demonstrates the persistence loop is healthy.

**Scope**:
- New `Views/Kanban/Components/PomodoroCountBadge.swift` — small pill showing "🍅 N" (use SF Symbol `circle.fill` or `leaf.fill` in tomato red to avoid emoji). Hidden when count == 0.
- `TaskCardView` — place it in the lower row (next to assignees / tags).
- The card needs to know the count and re-render when it changes. The cleanest path: a `PomodoroSessionStore` `@Observable` singleton that:
  - exposes `[UUID: Int]` of taskID → count.
  - listens for `.pomodoroWorkSessionCompleted` and refreshes the affected entry via `PomodoroSessionRepository.count(taskID:)`.
  - also exposes `refreshAll(items:)` for `KanbanViewModel.reload()` to call so initial counts are loaded.
- `KanbanViewModel.reload()` — after reloading items, call `PomodoroSessionStore.shared.refreshAll(items: items)`.

**Files**:
- `TaskBar/Views/Kanban/Components/PomodoroCountBadge.swift` (new).
- `TaskBar/Services/PomodoroSessionStore.swift` (new).
- `TaskBar/Views/Kanban/TaskCardView.swift` (modify — embed badge).
- `TaskBar/ViewModels/KanbanViewModel.swift` (modify — call `refreshAll`).

**Accept when**:
1. A card for a task with 0 completed Pomodoros shows no badge.
2. A task with 3 completed Pomodoros shows "🍅 3".
3. Starting and finishing a Pomodoro for that task makes the badge count go from 0 → 1 without an app restart.
4. Deleting a task does not break the store (orphan IDs are simply not displayed).
5. Counts persist across app relaunches (they come from SwiftData anyway).

### Chunk 5 — Tests

**Scope** (mirrors existing test style in `TaskBarTests/`):
- `PomodoroSessionStoreTests.swift` — verifies `refreshAll` populates the map and `.pomodoroWorkSessionCompleted` updates only the affected entry.
- `PomodoroTimerTests.swift` (extend) — new test for the "starting the same active task is a no-op" guard, and one for `currentProjectID` being set on `startWork`.
- `KanbanViewModelTests.swift` (extend) — verify that after `reload()`, `PomodoroSessionStore.shared` has entries for the loaded items.

**Files**:
- `TaskBarTests/PomodoroSessionStoreTests.swift` (new).
- `TaskBarTests/PomodoroTimerTests.swift` (extend).
- `TaskBarTests/KanbanViewModelTests.swift` (extend).

**Accept when**: `xcodebuild test -scheme TaskBar -destination 'platform=macOS'` is green for all targets.

## Key design choices

- **No new `@Model` entities, no schema bump.** Everything fits in the existing V3 schema (PomodoroSession already records `taskID`; we just read it more).
- **No new third-party deps.** Pure SwiftUI + SwiftData + AppKit (already used by `PomodoroWindowController`).
- **Reuse `PomodoroTimer.shared` (singleton)**. The existing wiring (notification observer, floating panel) assumes a single timer. Keeping the singleton avoids threading a new instance through the views and matches the existing `PomodoroTimer.shared.startWork(task:)` call site in `TaskDetailView`.
- **PomodoroSessionStore singleton** mirrors the `PomodoroTimer` pattern. Views observe it via `@State` (Observation framework) — no Combine boilerplate.
- **Picker scope = current project**. If `PomodoroTimer.currentProjectID` is `nil` (e.g. first launch), the picker falls back to all projects, grouped. Avoids an empty picker on a fresh install.
- **Switch-task mid-phase is a confirmable action** to prevent accidental loss of an in-progress session. The session is *not* recorded as complete (matches `PomodoroTimer.skip()` semantics).
- **Floating window resize via the panel's `setContentSize`** in `PomodoroWindowController`, driven by the timer's phase via observation. Keeps `PomodoroTimerView` layout-agnostic.

## Risks

- **Floating panel layout can glitch on resize.** Mitigation: animate the resize with `panel.animator().setContentSize(_:)` so the panel grows smoothly.
- **PomodoroSessionStore singleton lifetime across @Observable reloads.** Mitigation: only attach the notification observer once (lazy, idempotent). Detach in `deinit` is unnecessary for a singleton that lives for the app lifetime.
- **Drag of an active card during a focus pulse.** Mitigation: disable the pulse animation while the card is being dragged (`isPressed` / drop-target state).
- **Picker performance with many tasks.** Mitigation: cap the picker at the first 50 tasks; show "filter to narrow" if there are more. The kanban never shows more than a few dozen per column in practice.

## Open questions

None blocking. Surface during implementation if they become decisions:

1. Should the picker show tasks from all projects or only the currently-selected one in the sidebar? (Default: currently-selected project, fallback: all projects grouped.)
2. Should the active-focus indicator be a coloured ring, a left-edge accent, or a pill? (Default: a left-edge accent + a small pill, as in the design above.)
3. Should the floating window remember its position across launches, or always center on first show? (Default: remember via `UserDefaults` key `pomodoroPanelFrame` — small, additive, no schema changes.)