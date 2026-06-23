//
//  ModelContainerProvider.swift
//  TaskBar
//
//  Builds the shared SwiftData ModelContainer. Schema V4:
//  Project + WorkItem + PomodoroSession. On any schema mismatch the
//  existing store is wiped.
//
//  On first launch we seed demo data: a "Website Redesign" project
//  and four tasks distributed across columns.
//

import Foundation
import SwiftData

enum ModelContainerProvider {
    private static let schema = Schema([Project.self, WorkItem.self, PomodoroSession.self])

    static let shared: ModelContainer = makeSharedContainer()

    private static func makeSharedContainer() -> ModelContainer {
        do {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("ModelContainer creation failed (\(error)). Wiping store and retrying.")
            wipeStoreFile()
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try! ModelContainer(for: schema, configurations: [configuration])
        }
    }

    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeInMemoryWorkItemRepository() throws -> WorkItemRepository {
        try makeInMemoryRepositoryPair().workItemRepo
    }

    static func makeInMemoryProjectRepository() throws -> ProjectRepository {
        try makeInMemoryRepositoryPair().projectRepo
    }

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

    static func wipeStoreFile() {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else { return }
        let bundleID = "com.example.Mackanban"
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

    // MARK: - Seed

    static func seedDefaultProjectIfNeeded(in context: ModelContext) {
        let projectRepo = ProjectRepository(context: context)
        let workItemRepo = WorkItemRepository(context: context)
        guard (try? projectRepo.fetchAll().isEmpty) == true else { return }

        let project = try? projectRepo.create(
            name: "Website Redesign",
            colorHex: "#D49A6A",
            projectDescription: "Complete redesign of company website."
        )
        guard let project else { return }

        let inDays: (Int) -> Date = { days in
            Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        }

        _ = try? workItemRepo.create(title: "Product Redesign", status: .todo, priority: .medium, dueDate: inDays(7), tags: ["UI", "Design"], project: project)
        _ = try? workItemRepo.create(title: "Mobile App Beta", status: .doing, priority: .medium, dueDate: inDays(3), tags: ["UI", "Mobile"], project: project)
        _ = try? workItemRepo.create(title: "Performance Optimization", status: .doing, priority: .medium, dueDate: inDays(5), tags: ["Performance"], project: project)
        _ = try? workItemRepo.create(title: "API Integration for Tasks", status: .done, priority: .medium, dueDate: inDays(-2), tags: ["Backend", "API"], project: project)
    }
}
