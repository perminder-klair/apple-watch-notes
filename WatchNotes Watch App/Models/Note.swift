//
//  Note.swift
//  WatchNotes Watch App
//
//  This file defines the Note data model using SwiftData.
//  SwiftData is Apple's modern framework for data persistence (like a database).
//

import Foundation
import SwiftData

/// @Model is a SwiftData macro that makes this class persistable
/// It automatically handles saving/loading from local storage
@Model
final class Note {

    // MARK: - Properties

    /// Unique identifier for each note
    /// UUID generates a unique ID automatically when creating a new note
    var id: UUID

    /// The main content/text of the note
    var content: String

    /// When the note was first created
    var createdAt: Date

    /// When the note was last modified
    var updatedAt: Date

    /// Optional title for the note (user can leave it blank)
    var title: String

    /// Indicates if the note was created via voice input
    var wasVoiceInput: Bool

    // MARK: - Initializer

    /// Creates a new Note with the given content
    /// - Parameters:
    ///   - content: The text content of the note
    ///   - title: Optional title (defaults to empty string)
    ///   - wasVoiceInput: Whether this was created via voice (defaults to false)
    init(
        content: String,
        title: String = "",
        wasVoiceInput: Bool = false
    ) {
        self.id = UUID()
        self.content = content
        self.title = title
        self.wasVoiceInput = wasVoiceInput
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Helper Methods

    /// Updates the note content and refreshes the updatedAt timestamp
    func updateContent(_ newContent: String) {
        self.content = newContent
        self.updatedAt = Date()
    }

    /// Returns a preview of the note content (first 50 characters)
    /// Useful for showing in list views
    var preview: String {
        if content.isEmpty {
            return "Empty note"
        }
        let maxLength = 50
        if content.count <= maxLength {
            return content
        }
        return String(content.prefix(maxLength)) + "..."
    }

    /// Returns the title if set, otherwise returns the preview
    var displayTitle: String {
        if !title.isEmpty {
            return title
        }
        return preview
    }

    /// Formats the date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
}
