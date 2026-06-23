# TaskBar Revamp — Design Spec

**Date**: 2026-06-23
**Status**: Approved (verbal)

## Decisions (from brainstorming)

| # | Decision | Choice |
|---|----------|--------|
| 1 | App shape | Full window only (drop menu bar / `LSUIElement`) |
| 2 | Schema scope | Flatten everything (drop `WorkItemType`, `parent`/`children`, `WorkItemRelation`) |
| 3 | Column count | Keep 4 (`todo` / `doing` / `review` / `done`) |
| 4 | Tabs scope | Board-only with placeholders for List / Activity / Files |
| 5 | Assignee model | Full `TeamMember` model, many-to-many with `WorkItem` |

## Architecture

- `LSUIElement = NO`. Delete `AppDelegate`, `PopoverController`.
- `TaskBarApp` body: `WindowGroup { NavigationSplitView { SidebarView() } detail: { ProjectDetailView() } }`.
- Standard macOS title bar; default window ~1180×780, min ~960×600.
- MVVM + Repository — same shape as today.

## File plan

**Add**
- `Models/TeamMember.swift`
- `Views/Sidebar/SidebarView.swift`
- `Views/TopBar/TopBarView.swift`
- `Views/Project/ProjectDetailView.swift`
- `Views/Project/ProjectHeaderView.swift`
- `Views/Project/ProjectTabsView.swift`
- `Views/Project/Tabs/BoardTab.swift`
- `Views/Project/Tabs/ListTab.swift` (placeholder)
- `Views/Project/Tabs/ActivityTab.swift` (placeholder)
- `Views/Project/Tabs/FilesTab.swift` (placeholder)
- `Views/Assignee/AssigneeAvatarsView.swift`
- `Views/Assignee/AssigneePickerSheet.swift`
- `ViewModels/SidebarViewModel.swift`

**Delete**
- `App/AppDelegate.swift`
- `App/PopoverController.swift`
- `Models/WorkItemType.swift`
- `Models/WorkItemRelation.swift`

**Modify**
- `App/TaskBarApp.swift`
- `Info.plist` (remove `LSUIElement`)
- `Models/WorkItem.swift` (flatten + add assignees)
- `Persistence/ModelContainerProvider.swift` (schema V3 + seed)
- `Services/Theme.swift` (warm beige + glass tokens)
- `ViewModels/KanbanViewModel.swift` (drop type filter)
- `ViewModels/TaskEditorViewModel.swift` (drop type, add assignees)
- `ViewModels/QuickAddViewModel.swift` (drop type, add assignees)
- `Views/Kanban/KanbanColumnView.swift` (16-24 pt radii, glass)
- `Views/Kanban/TaskCardView.swift` (18 pt radius, assignees row)
- `Views/Kanban/KanbanBoardView.swift` (drop type references in preview)
- `Views/Task/QuickAddView.swift`, `TaskDetailView.swift`, `PriorityPicker.swift` (drop type, surface assignees)
- `Views/MenuBar/PopoverRootView.swift` — content moved into `ProjectDetailView`; delete if fully replaced
- `Persistence/WorkItemRepository.swift` (add assignee helpers)
- Tests in `TaskBarTests/`
- `TaskBarUITests/PlaceholderUITests.swift`

## Visual system

- Light palette: bg `#FAF7F2`, surface `#FFFFFF`, surfaceSubtle `#F2EEE7`, border `#E8E2D7`, accent `#1F1B16`, textPrimary `#1F1B16`, textSecondary `#6B6258`, textTertiary `#9C9387`.
- Dark palette: bg `#1C1A18`, surface `#252220`, surfaceSubtle `#2C2926`, border `#3A362F`, textPrimary `#F4EFE6`, accent `#F4EFE6`.
- Glass: `.ultraThinMaterial` over warm tint for sidebar.
- Radii: columns 20, cards 18, buttons 12, fields 12, popovers 20.
- Shadows: cards `0.04/8/2` resting, `0.08/14/6` hover. Sidebar/topbar no shadow.

## Data layer

- **`TeamMember`** — `@Model`: `id`, `name`, `initials` (derived), `colorHex` (deterministic), `role: String?`, `createdAt`. Inverse on `WorkItem.assignees`.
- **`WorkItem`** — drop `typeRaw`, `parent`, `children`. Add `assignees: [TeamMember]` many-to-many. Keep `status`, `priority`, `title`, `itemDescription`, `dueDate`, `tags`, `createdAt`, `updatedAt`, `project`.
- **`Project`** — unchanged.
- Schema V3; existing wipe-on-mismatch still applies.
- **Seed on first launch**: project "Website Redesign" / "Complete redesign of company website"; 3 `TeamMember`s (Ava Chen, Leo Park, Mia Sato); 4 tasks with the exact revamp.md titles, all Medium priority, tags `["UI", "Design"]`, due dates staggered over next 2 weeks. Distribution: To Do → "Product Redesign"; In Progress → "Mobile App Beta" + "Performance Optimization"; Review → empty placeholder; Done → "API Integration for Tasks". Assignees round-robin.

## UI surfaces

- **Sidebar**: logo + name; Dashboard / Projects / My Tasks / Calendar; Channels section with General; Team + Settings at bottom.
- **TopBar**: project color dot + name + chevron (project picker); right cluster: search field, bell, activity, profile avatar.
- **ProjectHeader**: bold title + secondary description.
- **ProjectTabs**: pill-style tabs (Board / List / Activity / Files).
- **Board**: existing `KanbanBoardView` wrapped in `BoardTab`, re-themed.
- **Card**: priority badge + due date top row; title; tags + assignee avatars bottom row.

## Out of scope

- Menu bar / popover / `LSUIElement`.
- Real Files / Activity / List views (placeholders only).
- Settings scene content (sidebar entry stubs to a placeholder).
- Keyboard shortcuts beyond existing ⌘+Shift+N.
- Third-party deps.

## Verification

- `xcodebuild -scheme TaskBar -destination 'platform=macOS' build` succeeds.
- `xcodebuild test -scheme TaskBar -destination 'platform=macOS'` passes extended suite.
- Manual smoke: window opens, sidebar nav works, project renders with 4 sample tasks across 4 columns, drag & drop persists, search filters, ⌘+Shift+N adds a task, dark mode + light mode both render warm palette.
