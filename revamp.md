Create a modern macOS project management application using SwiftUI with a clean, minimal, and premium design inspired by Notion, Linear, and Trello. The application should feature a Kanban board interface for task management.

Design Requirements
Native macOS application built entirely with SwiftUI.
Soft light theme with warm beige and white colors.
Rounded corners (16–24px radius) throughout the interface.
Subtle shadows and glassmorphism-inspired aesthetics.
Spacious layout with excellent visual hierarchy.
San Francisco font and native Apple Human Interface Guidelines.
Smooth animations and hover effects.
Window Layout
Left Sidebar
Fixed-width navigation sidebar.
App logo and application name at the top.
Navigation sections:
Dashboard
Projects
My Tasks
Calendar
Workspace channels section:
General
Bottom area:
Team
Settings
Selected menu item should have a highlighted background.
Top Navigation Bar
Centered project/workspace title.
Search bar positioned on the right.
Notification icon.
Activity icon.
User profile avatar.
macOS-style toolbar integration.
Main Content Area

Display a project named "Website Redesign".

Include project description:
"Complete redesign of company website."

Below the title, create tab navigation:

Board
List
Activity
Files
Kanban Board

Create three columns:

To Do
Product Redesign task card
In Progress
Mobile App Beta task card
Performance Optimization task card
Done
API Integration for Tasks task card
Task Card Design

Each task card should include:

Task title
Due date
Priority badge (Medium)
Assigned user avatars
Tags such as:
UI
Design
Hover animation
Drag-and-drop support between columns
Functionality
MVVM architecture.
SwiftData or Core Data persistence.
Drag and drop tasks between columns.
Add, edit, and delete tasks.
Search tasks in real time.
Responsive resizing for different macOS window sizes.
Smooth transitions using SwiftUI animations.
Support for Dark Mode and Light Mode.
Technical Requirements
SwiftUI NavigationSplitView for sidebar layout.
LazyVGrid/HStack for Kanban columns.
Reusable components:
SidebarView
TopBarView
KanbanColumnView
TaskCardView
ProjectHeaderView
Follow Apple's latest SwiftUI best practices.
Clean, maintainable, production-ready code.
Visual Style Keywords

Minimalist, Apple Design, macOS Native, Premium SaaS Dashboard, Clean UI, Soft Shadows, Glassmorphism, Modern Productivity App, Linear-inspired, Notion-inspired, Elegant, Professional.