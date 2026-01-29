import Foundation
import CoreData
import SwiftUI

// MARK: - TagEntity Extensions

extension TagEntity {
    // MARK: - Computed Properties

    /// The color for this tag
    var color: Color {
        Color(hex: colorHex ?? "#5E9EA0")
    }

    /// Tasks as an array for easier iteration
    var tasksArray: [TaskEntity] {
        let taskSet = tasks as? Set<TaskEntity> ?? []
        return Array(taskSet).sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }

    /// Number of incomplete tasks with this tag
    var incompleteTaskCount: Int {
        tasksArray.filter { !$0.isCompleted }.count
    }

    /// Number of all tasks with this tag
    var totalTaskCount: Int {
        tasksArray.count
    }

    // MARK: - Factory Methods

    /// Create a new tag with the given properties
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        colorHex: String = "#5E9EA0"
    ) -> TagEntity {
        let tag = TagEntity(context: context)
        tag.id = UUID()
        tag.name = name
        tag.colorHex = colorHex
        tag.createdAt = Date()
        return tag
    }

    // MARK: - Default Tags

    /// Create default tags for new users
    static func createDefaultTags(in context: NSManagedObjectContext) {
        let defaultTags: [(name: String, color: String)] = [
            ("Work", "#6B9AC4"),
            ("Personal", "#B2C9AB"),
            ("Health", "#7FB3A5"),
            ("Urgent", "#E07A5F"),
            ("Home", "#A7C4BC"),
        ]

        for (name, colorHex) in defaultTags {
            let tag = TagEntity(context: context)
            tag.id = UUID()
            tag.name = name
            tag.colorHex = colorHex
            tag.createdAt = Date()
        }
    }
}

// MARK: - Fetch Requests

extension TagEntity {
    /// Fetch request for all tags sorted by name
    static func allTags() -> NSFetchRequest<TagEntity> {
        let request = NSFetchRequest<TagEntity>(entityName: "TagEntity")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TagEntity.name, ascending: true)
        ]
        return request
    }

    /// Fetch request to find a tag by name
    static func tag(named name: String) -> NSFetchRequest<TagEntity> {
        let request = NSFetchRequest<TagEntity>(entityName: "TagEntity")
        request.predicate = NSPredicate(format: "name ==[cd] %@", name)
        request.fetchLimit = 1
        return request
    }

    /// Check if a tag with the given name already exists
    static func exists(named name: String, in context: NSManagedObjectContext) -> Bool {
        let request = tag(named: name)
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
}
