# TaskBar — Implementation Plan

## Goal
Build the macOS menu bar Kanban app described in `mackanban.md` (codename **TaskBar**): a SwiftUI app using SwiftData persistence, MVVM architecture, drag & drop between columns, search, ⌘+Shift+N quick-add, and local persistence — targeting macOS 15+, runnable locally.

## Constraints
- macOS 15+, Swift 5.10+, SwiftUI, SwiftData, MVVM (per PRD §8).
- Local-run distribution only (no code signing, no App Sandbox entitlements, no App Store submission).
- Xcode project (`.xcodeproj`) — chosen by user.
- Two test suites: **Swift Testing** for unit tests, **XCTest** for UI tests.
- All data local via SwiftData; no network, no iCloud (V2 only).
- No new third-party dependencies; use only Apple frameworks (`SwiftUI`, `SwiftData`, `AppKit` interop, `UniformTypeIdentifiers`).
- Success metrics from PRD §10 must be verifiable: launch <1s, menu bar interaction <200ms, 100+ tasks without lag.

## Architecture (MVVM + Repository)

```
TaskBar/
├── TaskBar.xcodeproj
├── TaskBar/
│   ├── App/
│   │   ├── TaskBarApp.swift            # @main, wires ModelContainer + MenuBarExtra
│   │   └── Info.plist                  # LSUIElement = YES
│   ├── Models/
│   │   ├── TaskItem.swift              # @Model — SwiftData entity (PRD §9)
│   │   ├── TaskStatus.swift            # enum: todo, doing, done
│   │   └── Priority.swift              # enum: low, medium, high
│   ├── Persistence/
│   │   ├── ModelContainerProvider.swift # shared ModelContainer for the app
│   │   └── TaskRepository.swift        # CRUD + queries against ModelContext
│   ├── ViewModels/
│   │   ├── KanbanViewModel.swift       # @Observable — groupings, search filter
│   │   ├── TaskEditorViewModel.swift   # add/edit form state
│   │   └── QuickAddViewModel.swift     # quick-add sheet state
│   ├── Views/
│   │   ├── MenuBar/
│   │   │   └── PopoverRootView.swift   # root inside MenuBarExtra popover
│   │   ├── Kanban/
│   │   │   ├── KanbanBoardView.swift   # 3-column layout
│   │   │   ├── KanbanColumnView.swift  # drop target
│   │   │   └── TaskCardView.swift      # draggable card
│   │   ├── Task/
│   │   │   ├── QuickAddView.swift      # ⌘+Shift+N sheet (title + description)
│   │   │   ├── TaskDetailView.swift    # full edit (title, desc, priority, due, tags)
│   │   │   └── PriorityPicker.swift
│   │   └── Common/
│   │       ├── SearchBarView.swift     # text field bound to KanbanViewModel
│   │       └── EmptyColumnView.swift
│   ├── Services/
│   │   ├── SearchService.swift         # pure filter logic (testable)
│   │   └── KeyboardShortcuts.swift     # ⌘+Shift+N global handler
│   └── Assets.xcassets/                # SF Symbols only, no custom icon for now
├── TaskBarTests/                       # Swift Testing target
│   ├── TaskRepositoryTests.swift
│   ├── SearchServiceTests.swift
│   └── KanbanViewModelTests.swift
└── TaskBarUITests/                     # XCTest target
    └── KanbanFlowUITests.swift
```

### Key design choices
- **MenuBarExtra** (SwiftUI, macOS 13+) drives the popover — no dock icon because `LSUIElement = YES`.
- **ModelContainer** built once in `TaskBarApp` and injected via `.modelContainer(...)` so `Environment(\.modelContext)` is available everywhere.
- **Drag & drop**: `.draggable(TaskTransferable)` + `.dropDestination(for: TaskTransferable.self)` on each `KanbanColumnView`. Drop resolves to `taskRepository.updateStatus(id, to:)`.
- **Search**: text-bound `KanbanViewModel.searchText`; filter pipeline is a pure function in `SearchService` so it's unit-testable without SwiftData.
- **Quick add**: a `MenuBarExtra`-wide `@State var showQuickAdd = false` toggled by a hidden `Button` carrying `.keyboardShortcut("n", modifiers: [.command, .shift])`. Falls back to `NSEvent.addLocalMonitor` if the popover-keyboard shortcut proves unreliable.
- **Persistence path**: SwiftData default location in `~/Library/Application Support` (default container), which already survives app relaunch.

## Chunks

### Chunk 1 — Project scaffolding
**Scope**: Xcode project, target config, Info.plist, placeholder MenuBarExtra, folder skeleton.
**Depends On**: none.
**Accept When**:
- `xcodebuild -scheme TaskBar -destination 'platform=macOS' build` succeeds.
- App launches, shows a `checklist` SF Symbol in the menu bar, popover opens with "TaskBar — hello" placeholder.
- `LSUIElement = YES` confirmed in built `Info.plist` (no Dock icon).
**Open Questions**: none (use SF Symbol `checklist` for icon, decided).

### Chunk 2 — Data layer (Model + Repository + SwiftData)
**Scope**: `TaskItem` `@Model` with PRD §9 fields, `TaskStatus`/`Priority` enums (Codable, CaseIterable), `ModelContainerProvider`, `TaskRepository` CRUD.
**Depends On**: Chunk 1.
**Accept When**:
- `TaskRepositoryTests` (Swift Testing) pass: create, read, update status/priority/dueDate, delete, fetch-by-status.
- An in-memory container test proves CRUD round-trips work.
- A launch test writes a task, relaunches (in code via `ModelConfiguration(isStoredInMemoryOnly: false)`), and confirms the task is present.

### Chunk 3 — ViewModels
**Scope**: `KanbanViewModel` (groups tasks by status, applies search), `TaskEditorViewModel` (form validation), `QuickAddViewModel` (minimal — title + description).
**Depends On**: Chunk 2.
**Accept When**:
- `KanbanViewModelTests` (Swift Testing) pass: empty input → 3 empty buckets; unsorted input → grouped correctly; search "x" filters to matches in title/tags/status display label.
- `SearchServiceTests` cover substring (case-insensitive), tag match, status match, no-match.

### Chunk 4 — Kanban UI (columns + cards, no drag yet)
**Scope**: `PopoverRootView` (search bar + board + "+" button), `KanbanBoardView`, `KanbanColumnView`, `TaskCardView` (title, priority badge, due-date pill).
**Depends On**: Chunk 3.
**Accept When**:
- Popover renders three columns with sample tasks loaded from `TaskRepository`.
- Columns are independently scrollable (`ScrollView` + `LazyVStack`).
- Priority badge color matches `Priority` (low=gray, medium=blue, high=red).
- Manual: popover open + render with 50 tasks feels instant (<200ms after first paint).

### Chunk 5 — CRUD: add, edit, delete
**Scope**: `QuickAddView` sheet (title + description + Save), `TaskDetailView` (all PRD §4.4 fields), delete via context menu on card, all wired through `TaskRepository`.
**Depends On**: Chunk 4.
**Accept When**:
- "+" opens `QuickAddView`; Save creates a task in `todo` column.
- Clicking a card opens `TaskDetailView`; edits persist after closing the popover and relaunching.
- Right-click → Delete removes the task and persists.
- Empty title is rejected (form validation).

### Chunk 6 — Drag & drop between columns
**Scope**: `TaskTransferable` (`Transferable`), `.draggable` on `TaskCardView`, `.dropDestination` on `KanbanColumnView`; on drop, call `TaskRepository.updateStatus`.
**Depends On**: Chunk 5.
**Accept When**:
- Drag a card from Todo to Doing → on drop, card appears in Doing and `task.status == .doing` in storage.
- Same for Doing→Done and Done→Todo.
- Drop into the same column is a no-op (no flicker, no extra save).
- Persists after relaunch.

### Chunk 7 — Search
**Scope**: `SearchBarView` at top of popover, bound to `KanbanViewModel.searchText`; filter pipeline uses `SearchService`.
**Depends On**: Chunk 6.
**Accept When**:
- Typing "fix" hides non-matching cards in real time.
- Search matches against title (case-insensitive substring), any tag, and status display label ("todo", "doing", "done").
- Clearing the search restores all cards.

### Chunk 8 — Keyboard shortcut ⌘+Shift+N
**Scope**: Hidden `Button` with `.keyboardShortcut("n", modifiers: [.command, .shift])` inside the popover; opens `QuickAddView` regardless of focus inside the popover. Add `KeyboardShortcuts.swift` as an `NSEvent` fallback if needed.
**Depends On**: Chunk 5.
**Accept When**:
- With the popover open, ⌘+Shift+N opens `QuickAddView`.
- If `Button.keyboardShortcut` doesn't fire reliably, the `NSEvent` monitor succeeds.

### Chunk 9 — Performance polish + success-metrics verification
**Scope**: Convert columns to `LazyVStack`, debounce search if needed, freeze heavy views with `@State`/`let`, profile with Instruments (Time Profiler + Hangs).
**Depends On**: Chunk 7, Chunk 8.
**Accept When**:
- Cold launch < 1.0s on a developer machine.
- Menu bar icon → fully rendered popover < 200ms (Instruments Time Profiler).
- Inserting 100+ tasks leaves the popover interactive.

### Chunk 10 — UI test + final smoke
**Scope**: `KanbanFlowUITests` (XCTest) covering: launch → click menu bar icon → quick-add a task → drag to Done → quit → relaunch → assert task is still in Done.
**Depends On**: Chunk 9.
**Accept When**:
- `xcodebuild test -scheme TaskBar -destination 'platform=macOS'` runs all unit + UI tests and they pass.
- Manual smoke: add, edit, drag, search, quit, reopen — all behave per PRD §6.

## Verification Strategy
- Per chunk: run the chunk's accept criteria; do not mark complete until verified.
- Per chunk that touches persistence: kill the app process and relaunch, confirm state.
- Final: `xcodebuild test` for both test targets; manual run of success-metrics scenarios.

## Decision Log
- **Xcode project over SPM-only**: required for SwiftData + future App Store wrapper.
- **Local-run distribution**: avoids signing/entitlements overhead; can be hardened later without code changes.
- **MenuBarExtra over NSStatusItem + NSPopover**: native SwiftUI, less AppKit glue. Fallback to AppKit if popover size constraints bite.
- **Swift Testing + XCTest**: Swift Testing for pure-logic unit tests, XCTest for UI integration.
- **SF Symbol `checklist` as menu bar icon**: zero asset work; replace with custom icon later.
- **No third-party deps**: keeps the binary small and App-Store-friendly later.

## Risks
- **SwiftData on macOS 15.0** had schema-migration bugs. *Mitigation*: target macOS 15.6+ if available; pin Xcode to latest stable.
- **Drag & drop inside MenuBarExtra popover** can fail to register drops on some macOS versions. *Mitigation*: Chunk 6 has a documented fallback (context-menu "Move to").
- **⌘+Shift+N while popover not key** may not fire `keyboardShortcut`. *Mitigation*: `NSEvent.addLocalMonitor` fallback in Chunk 8.
- **Popover height cap** (~700pt default) may truncate a 3-column kanban at small widths. *Mitigation*: responsive layout — single-column at narrow widths, 3-column from ~520pt up; documented in Chunk 4.
- **Success metrics depend on the dev machine** — PRD doesn't specify hardware. *Mitigation*: state the baseline machine in the final report; metrics are sanity checks, not absolute SLAs.

## Open Questions
None outstanding. All assumptions surfaced during planning were either confirmed via the questionnaire or decided with a safe default documented in the Decision Log.
