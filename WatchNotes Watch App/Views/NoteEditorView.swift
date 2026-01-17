//
//  NoteEditorView.swift
//  WatchNotes Watch App
//
//  This view allows users to create and edit notes.
//  It supports both keyboard input (using watchOS dictation/scribble)
//  and dedicated voice input mode.
//

import SwiftUI
import SwiftData

/// Defines how the user wants to input text
enum InputMode {
    case keyboard  // Uses standard TextField with dictation/scribble
    case voice     // Uses dedicated voice recording view
}

/// NoteEditorView handles both creating new notes and editing existing ones
struct NoteEditorView: View {

    // MARK: - Environment

    /// Access to SwiftData for saving notes
    @Environment(\.modelContext) private var modelContext

    /// Used to dismiss this view and go back
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    /// The note being edited (nil if creating a new note)
    let note: Note?

    /// How the user wants to input text
    let inputMode: InputMode

    // MARK: - State

    /// The current text content being edited
    @State private var content: String = ""

    /// Optional title for the note
    @State private var title: String = ""

    /// Whether voice recording is active
    @State private var isRecordingVoice = false

    /// Tracks if this note was created via voice
    @State private var wasVoiceInput: Bool = false

    // MARK: - Computed Properties

    /// True if we're editing an existing note (vs creating new)
    private var isEditing: Bool {
        note != nil
    }

    /// The title shown in the navigation bar
    private var navigationTitle: String {
        if isEditing {
            return "Edit Note"
        }
        return inputMode == .voice ? "Voice Note" : "New Note"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Title field (optional)
                titleSection

                // Content input area
                contentSection

                // Voice input button (when in voice mode)
                if inputMode == .voice || wasVoiceInput {
                    voiceInputSection
                }

                // Save button
                saveButton
            }
            .padding()
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExistingNote()
        }
    }

    // MARK: - Subviews

    /// Title input field
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Title (optional)")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("Add title...", text: $title)
                .textFieldStyle(.plain)
        }
    }

    /// Main content input area
    /// On watchOS, TextField automatically supports:
    /// - Dictation (speak to type)
    /// - Scribble (draw letters)
    /// - Emoji
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Note")
                .font(.caption)
                .foregroundColor(.secondary)

            // TextEditor for multi-line input
            // On watchOS, tapping this opens the system input interface
            TextField(
                "Start typing or use dictation...",
                text: $content,
                axis: .vertical
            )
            .lineLimit(5...10)
            .textFieldStyle(.plain)
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
    }

    /// Voice input section with microphone button
    private var voiceInputSection: some View {
        VStack(spacing: 8) {
            Divider()

            Text("Or use voice input")
                .font(.caption)
                .foregroundColor(.secondary)

            NavigationLink {
                VoiceInputView { transcribedText in
                    // Append transcribed text to content
                    if content.isEmpty {
                        content = transcribedText
                    } else {
                        content += " " + transcribedText
                    }
                    wasVoiceInput = true
                }
            } label: {
                HStack {
                    Image(systemName: "mic.fill")
                    Text("Record Voice")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
    }

    /// Save button at the bottom
    private var saveButton: some View {
        Button {
            saveNote()
        } label: {
            HStack {
                Image(systemName: "checkmark")
                Text(isEditing ? "Update" : "Save")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Methods

    /// Loads existing note data when editing
    private func loadExistingNote() {
        if let note = note {
            content = note.content
            title = note.title
            wasVoiceInput = note.wasVoiceInput
        } else if inputMode == .voice {
            wasVoiceInput = true
        }
    }

    /// Saves the note (creates new or updates existing)
    private func saveNote() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        if let existingNote = note {
            // Update existing note
            existingNote.content = trimmedContent
            existingNote.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            existingNote.updatedAt = Date()
            existingNote.wasVoiceInput = wasVoiceInput
        } else {
            // Create new note
            let newNote = Note(
                content: trimmedContent,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                wasVoiceInput: wasVoiceInput
            )
            modelContext.insert(newNote)
        }

        // Go back to the list
        dismiss()
    }
}

// MARK: - Preview

#Preview("New Note") {
    NavigationStack {
        NoteEditorView(note: nil, inputMode: .keyboard)
    }
    .modelContainer(for: Note.self, inMemory: true)
}

#Preview("Voice Note") {
    NavigationStack {
        NoteEditorView(note: nil, inputMode: .voice)
    }
    .modelContainer(for: Note.self, inMemory: true)
}
