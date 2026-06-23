# Revamp Exploration — Current State vs. revamp.md Target

## Current State (what exists)

### App shape
- **Menu bar app**: `LSUIElement = YES`, NSStatusItem with `checklist` SF Symbol, NSPopover 1180×700.
- **Entry**: `TaskBarApp` (`@main`) → `Settings { EmptyView() }` scene only. Real UI owned by `AppDelegate` + `PopoverController`.
- `AppDelegate.applicationDidFinishLaunching` calls `NSApp.setActivationPolicy(.accessory)` and installs the popover.

### Persistence (SwiftData)
- `Project` — `@Model` with id, name, colorHex, createdAt, projectDescription, inverse-relationship to WorkItems.
- `WorkItem` — id, title, itemDescription, typeRaw, statusRaw, priorityRaw, createdAt, updatedAt, dueDate, tagsJoined, project, parent, children.
- `WorkItemRelation` — separate join table for many-to-many "related" links.
- `ModelContainerProvider` builds the shared container, provides in-memory test container, seeds a default "Personal" project on first launch.

### Domain enums
- `TaskStatus`: `.todo`, `.doing`, `.review`, `.done` (4 columns). Icons + muted dot colors per status.
- `Priority`: `.low`, `.medium`, `.high`. Dot color + sort weight.
- `WorkItemType`: `.epic`, `.story`, `.task` (hierarchy).

### UI / Views
- `PopoverRootView` — root inside the popover. **Sidebar was REMOVED** (comment says so); replaced by a project Menu in the top bar.
- Top bar: project Menu, search bar (max 420pt), theme picker button, "+ New task" button (with ⌘+Shift+N).
- `KanbanBoardView` — `ViewThatFits` HStack (4 columns) / VStack (narrow widths).
- `KanbanColumnView` — header, ScrollView+LazyVStack of cards, footer "+ Add task". `.dropDestination(for: String.self)` for drag-and-drop. Cards are `.draggable(task.id.uuidString)`.
- `TaskCardView` — meta row (type icon+label, priority dot+label), title (size 19 semibold), parent chip, lower row (tags Capsule, due date pill). Rounded 8px, soft shadow. Hover lift.
- `Sidebar/NewProjectSheet` — name + color palette picker.
- `Views/Task/` — `QuickAddView`, `TaskDetailView` (full editor: type, priority, due date, tags, description), `PriorityPicker` (segmented).
- `Views/Common/SearchBarView` — plain rounded search input.

### Theme
- `Theme` struct + `Theme.light` / `Theme.dark` palettes.
- Light: `#FFFFFF` bg, `#F7F7F7` surfaceSubtle, `#E5E5E5` border, `.black` accent, near-black text — cool/Notion-style.
- Dark: `#141416` bg, warm near-white text, `.white` accent.
- `ThemeManager` is `@Observable`, persists to `UserDefaults`, broadcasts `.themeChanged` notification.
- Rounded corners everywhere are **8px** (cards, buttons, fields, columns).

### ViewModels & services
- `KanbanViewModel` — selectedProject, typeFilter, searchText, items, groupedItems, allItemsInProject. reload/move/delete/relate.
- `QuickAddViewModel` — title, itemDescription, canSave, save (status=.todo).
- `TaskEditorViewModel` — full editor state, save creates or updates.
- `SearchService` — pure filter (title/desc/tags/status/type, case-insensitive), groupByStatus, sortForColumn.

### Tests
- `KanbanViewModelTests`, `ProjectRepositoryTests`, `SearchServiceTests`, `WorkItemRepositoryTests` (XCTest).
- `TaskBarUITests/PlaceholderUITests.swift`.
- All XCTest (the plan mentioned Swift Testing but the repo went with XCTest).

---

## revamp.md Target

### Visual / structural
- **Full macOS window app** — not menu bar popover.
- **NavigationSplitView** sidebar: app logo + name at top; Dashboard, Projects, My Tasks, Calendar; channels section (General); bottom Team + Settings.
- **Top bar**: centered project title; search on right; notification icon, activity icon, profile avatar; macOS-style toolbar.
- **Project header**: title "Website Redesign", description "Complete redesign of company website."
- **Tabs under header**: Board, List, Activity, Files.
- **3 columns only**: To Do / In Progress / Done.
- **Task cards**: title, due date, priority badge (Medium), assigned user avatars, tags (UI, Design).
- Hover animation, drag-and-drop.

### Design tokens
- Soft light theme with **warm beige and white**.
- Rounded corners **16–24px**.
- Subtle shadows + glassmorphism.
- San Francisco font + HIG.
- Smooth animations + hover effects.

### Sample content
- Project: "Website Redesign" / "Complete redesign of company website."
- To Do: "Product Redesign"
- In Progress: "Mobile App Beta", "Performance Optimization"
- Done: "API Integration for Tasks"

### Functional (largely already exists)
- MVVM ✓
- SwiftData ✓
- Drag and drop ✓
- Add / edit / delete ✓
- Search ✓
- Responsive resize (ViewThatFits already) ✓
- Smooth transitions ✓
- Light + Dark ✓
- Reusable components — partially (need SidebarView, TopBarView, KanbanColumnView, TaskCardView, ProjectHeaderView explicitly)

---

## What changes vs. stays

### Will need to change
1. **App entry**: drop `LSUIElement = YES`, replace Settings-only scene with a `WindowGroup` + `NavigationSplitView`.
2. **Window ownership**: remove `AppDelegate` + `PopoverController`, OR repurpose them. The popover lifecycle was deliberately AppKit for click-to-reopen bug.
3. **Sidebar**: reintroduce as full NavigationSplitView sidebar with the spec's sections (Dashboard, Projects, My Tasks, Calendar, channels/General, Team, Settings).
4. **Top bar**: rebuild around centered title + right-side cluster (search, bell, activity, avatar).
5. **Project header**: new component above the columns.
6. **Tabs**: Board/List/Activity/Files — at minimum a stub for non-Board tabs.
7. **Column count**: 4 → 3 (drop `.review`) OR keep 4 (the spec is illustrative).
8. **Card design**: add assigned-user avatars row; current card has title / type / priority / parent / tags / due date.
9. **Rounded corners**: 8 → 16–24px throughout.
10. **Color palette**: cool grays → warm beige + white; add glassmorphism tokens.
11. **Sample data**: seed "Website Redesign" project with the 4 named tasks + their tags (UI, Design) + priority Medium + due dates.

### Stays the same (probably)
- SwiftData schema (Project, WorkItem, WorkItemRelation) — schemas are local-dev-only and can be wiped.
- Repositories (ProjectRepository, WorkItemRepository) — CRUD is still the right shape.
- ViewModels (KanbanViewModel, TaskEditorViewModel, QuickAddViewModel).
- SearchService logic — pure functions are easy to retest.
- Drag & drop mechanism (`.draggable` + `.dropDestination`).
- Test suite (extend, don't rewrite).
- Theme plumbing (`Environment(\.theme)`, `ThemeManager`, `AppTheme` enum).

### Open decision points
1. **Menu bar**: drop entirely (cleaner) vs. keep as a secondary entry point.
2. **Column count**: 3 (spec) vs. keep 4 (`.review`).
3. **Hierarchy**: keep epic/story/task vs. flatten to single WorkItem.
4. **Tabs**: full implementations vs. placeholders.
5. **Avatars**: SF Symbol initials vs. generated color circles vs. asset images.
6. **Glassmorphism**: real `.ultraThinMaterial` vs. faux translucent surface.
7. **Existing data**: wipe on launch vs. migrate.
