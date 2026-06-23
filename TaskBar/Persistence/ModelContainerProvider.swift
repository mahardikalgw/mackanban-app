//
//  ModelContainerProvider.swift
//  TaskBar
//
//  Builds the shared SwiftData ModelContainer. Schema V3:
//  Project + WorkItem (flattened, no hierarchy, no relations) +
//  TeamMember (many-to-many assignees). On any schema mismatch the
//  existing store is wiped — this is a local-dev app and prior data
//  is non-essential.
//
//  On first launch we seed the demo data the revamp spec asks for:
//  a "Website Redesign" project, three TeamMembers, and four tasks
//  distributed across the four columns.
//

import Foundation
import SwiftData

enum ModelContainerProvider {
    private static let schema = Schema([Project.self, WorkItem.self, TeamMember.self, PomodoroSession.self])

    /// Shared container used by the running app.
    static let shared: ModelContainer = makeSharedContainer()

    private static func makeSharedContainer() -> ModelContainer {
        do {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("ModelContainer creation failed (\(error)). Wiping store and retrying.")
            wipeStoreFile()
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            // swiftlint:disable:next force_try
            return try! ModelContainer(for: schema, configurations: [configuration])
        }
    }

    /// Build an isolated in-memory container for unit tests.
    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Convenience for tests that want a non-main context to avoid
    /// `mainContext`'s @MainActor isolation.
    static func makeInMemoryWorkItemRepository() throws -> WorkItemRepository {
        try makeInMemoryRepositoryPair().workItemRepo
    }

    static func makeInMemoryProjectRepository() throws -> ProjectRepository {
        try makeInMemoryRepositoryPair().projectRepo
    }

    /// Shared in-memory store containing Projects, WorkItems, and
    /// TeamMembers. Use this in tests where items need to reference
    /// projects and members in the same SwiftData container.
    static func makeInMemoryRepositoryPair() throws
        -> (workItemRepo: WorkItemRepository, projectRepo: ProjectRepository, project: Project)
    {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let workItemRepo = WorkItemRepository(context: context)
        let projectRepo = ProjectRepository(context: context)
        let project: Project
        if let existing = try projectRepo.fetchAll().first {
            project = existing
        } else {
            project = try projectRepo.create(name: "Personal", colorHex: "#5C95FF")
        }
        return (workItemRepo, projectRepo, project)
    }

    // MARK: - Store management

    /// Removes the default SwiftData store file. Used when the schema
    /// changes in a non-migration-compatible way.
    static func wipeStoreFile() {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else { return }
        let bundleID = "com.example.TaskBar"
        let candidates = [
            appSupport.appendingPathComponent(bundleID, isDirectory: true),
            appSupport
        ]
        for dir in candidates {
            for ext in ["store", "store-shm", "store-wal"] {
                let url = dir.appendingPathComponent("default.\(ext)")
                try? fm.removeItem(at: url)
            }
            if let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for url in contents where url.lastPathComponent.hasSuffix(".store")
                    || url.lastPathComponent.hasSuffix(".store-shm")
                    || url.lastPathComponent.hasSuffix(".store-wal") {
                    try? fm.removeItem(at: url)
                }
            }
        }
    }

    /// Seed the revamp demo content on first launch into the running app.
    /// Idempotent: only seeds when the store is empty.
    static func seedDefaultProjectIfNeeded(in context: ModelContext) {
        let projectRepo = ProjectRepository(context: context)
        let workItemRepo = WorkItemRepository(context: context)
        let memberRepo = TeamMemberRepository(context: context)
        guard (try? projectRepo.fetchAll().isEmpty) == true else { return }

        let project = try? projectRepo.create(
            name: "Website Redesign",
            colorHex: "#D49A6A",
            projectDescription: "Complete redesign of company website."
        )
        guard let project else { return }

        let members: [TeamMember]
        do {
            members = try [
                memberRepo.create(name: "Ava Chen", role: "Designer"),
                memberRepo.create(name: "Leo Park", role: "Engineer"),
                memberRepo.create(name: "Mia Sato", role: "PM")
            ]
        } catch {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let inDays: (Int) -> Date = { days in
            calendar.date(byAdding: .day, value: days, to: now) ?? now
        }

        // To Do
        _ = try? workItemRepo.create(
            title: "Product Redesign",
            status: .todo,
            priority: .medium,
            dueDate: inDays(7),
            tags: ["UI", "Design"],
            project: project,
            assignees: [members[0], members[2]]
        )
        // In Progress
        _ = try? workItemRepo.create(
            title: "Mobile App Beta",
            status: .doing,
            priority: .medium,
            dueDate: inDays(3),
            tags: ["UI", "Mobile"],
            project: project,
            assignees: [members[0], members[1]]
        )
        _ = try? workItemRepo.create(
            title: "Performance Optimization",
            status: .doing,
            priority: .medium,
            dueDate: inDays(5),
            tags: ["Performance"],
            project: project,
            assignees: [members[1]]
        )
        // Done
        _ = try? workItemRepo.create(
            title: "API Integration for Tasks",
            status: .done,
            priority: .medium,
            dueDate: inDays(-2),
            tags: ["Backend", "API"],
            project: project,
            assignees: [members[1], members[2]]
        )
    }
}
