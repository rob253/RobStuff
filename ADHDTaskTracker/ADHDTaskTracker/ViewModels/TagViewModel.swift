import Foundation
import CoreData
import SwiftUI

/// TagViewModel manages tag-related operations and state
@MainActor
class TagViewModel: ObservableObject {
    // MARK: - Published Properties

    /// All tags from Core Data
    @Published var tags: [TagEntity] = []

    /// Loading state
    @Published var isLoading: Bool = false

    /// Error message for display
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let viewContext: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        fetchTags()
        createDefaultTagsIfNeeded()
    }

    // MARK: - Fetch Tags

    /// Fetch all tags from Core Data
    func fetchTags() {
        isLoading = true

        let request = TagEntity.allTags()

        do {
            tags = try viewContext.fetch(request)
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch tags: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - CRUD Operations

    /// Create a new tag
    /// - Parameters:
    ///   - name: The tag name
    ///   - colorHex: The color hex string
    /// - Returns: True if created successfully, false if duplicate
    @discardableResult
    func createTag(name: String, colorHex: String = "#5E9EA0") -> Bool {
        // Check for duplicate names
        if TagEntity.exists(named: name, in: viewContext) {
            errorMessage = "A tag with this name already exists"
            return false
        }

        let _ = TagEntity.create(in: viewContext, name: name, colorHex: colorHex)
        saveContext()
        fetchTags()
        return true
    }

    /// Update an existing tag
    /// - Parameters:
    ///   - tag: The tag to update
    ///   - name: New name (optional)
    ///   - colorHex: New color (optional)
    func updateTag(_ tag: TagEntity, name: String? = nil, colorHex: String? = nil) {
        if let name = name {
            // Check for duplicate names (excluding current tag)
            let existingTags = tags.filter { $0.name?.lowercased() == name.lowercased() && $0.id != tag.id }
            if !existingTags.isEmpty {
                errorMessage = "A tag with this name already exists"
                return
            }
            tag.name = name
        }

        if let colorHex = colorHex {
            tag.colorHex = colorHex
        }

        saveContext()
        fetchTags()
    }

    /// Delete a tag
    /// - Parameter tag: The tag to delete
    func deleteTag(_ tag: TagEntity) {
        viewContext.delete(tag)
        saveContext()
        fetchTags()
    }

    /// Delete multiple tags
    /// - Parameter tagsToDelete: Array of tags to delete
    func deleteTags(_ tagsToDelete: [TagEntity]) {
        for tag in tagsToDelete {
            viewContext.delete(tag)
        }
        saveContext()
        fetchTags()
    }

    // MARK: - Default Tags

    /// Create default tags if none exist
    private func createDefaultTagsIfNeeded() {
        guard tags.isEmpty else { return }

        TagEntity.createDefaultTags(in: viewContext)
        saveContext()
        fetchTags()
    }

    // MARK: - Helper Methods

    /// Save the view context
    private func saveContext() {
        do {
            try viewContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    /// Find a tag by ID
    func tag(withId id: UUID) -> TagEntity? {
        tags.first { $0.id == id }
    }

    /// Find a tag by name
    func tag(named name: String) -> TagEntity? {
        tags.first { $0.name?.lowercased() == name.lowercased() }
    }

    /// Get tags sorted by usage count
    var tagsByUsage: [TagEntity] {
        tags.sorted { $0.totalTaskCount > $1.totalTaskCount }
    }

    /// Get the most used tags (top 5)
    var popularTags: [TagEntity] {
        Array(tagsByUsage.prefix(5))
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
