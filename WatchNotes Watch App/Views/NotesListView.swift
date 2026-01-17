//
//  NotesListView.swift
//  WatchNotes Watch App
//
//  This view displays all saved notes in a scrollable list.
//  Users can tap a note to edit it, or use the + button to create new notes.
//

import SwiftUI
import SwiftData

/// NotesListView shows all notes and provides navigation to create/edit notes
struct NotesListView: View {

    // MARK: - Environment & Query

    /// @Environment gives access to the SwiftData model context
    /// The modelContext is used to save, delete, and manage Note objects
    @Environment(\.modelContext) private var modelContext

    /// @Query automatically fetches all Note objects from SwiftData
    /// The sort parameter orders notes by updatedAt (newest first)
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    // MARK: - State

    /// Controls whether the "new note" action sheet is shown
    @State private var showingNewNoteOptions = false

    // MARK: - Body

    var body: some View {
        Group {
            if notes.isEmpty {
                // Show empty state when there are no notes
                emptyStateView
            } else {
                // Show the list of notes
                notesList
            }
        }
        .navigationTitle("Notes")
        .toolbar {
            // Add button in the toolbar
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewNoteOptions = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // Action sheet for choosing input method (type or speak)
        .confirmationDialog(
            "Create Note",
            isPresented: $showingNewNoteOptions,
            titleVisibility: .visible
        ) {
            NavigationLink {
                NoteEditorView(note: nil, inputMode: .keyboard)
            } label: {
                Label("Type Note", systemImage: "keyboard")
            }

            NavigationLink {
                NoteEditorView(note: nil, inputMode: .voice)
            } label: {
                Label("Voice Note", systemImage: "mic")
            }
        }
    }

    // MARK: - Subviews

    /// View shown when there are no notes yet
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No Notes Yet")
                .font(.headline)

            Text("Tap + to create your first note")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    /// List of all notes with swipe-to-delete
    private var notesList: some View {
        List {
            ForEach(notes) { note in
                NavigationLink {
                    // Navigate to editor when tapping a note
                    NoteEditorView(note: note, inputMode: .keyboard)
                } label: {
                    NoteRowView(note: note)
                }
            }
            .onDelete(perform: deleteNotes)
        }
    }

    // MARK: - Methods

    /// Deletes notes at the specified indices
    /// Called when user swipes to delete
    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            let note = notes[index]
            modelContext.delete(note)
        }
        // SwiftData automatically saves changes
    }
}

// MARK: - Note Row View

/// A single row in the notes list showing note preview and metadata
struct NoteRowView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                // Show mic icon if note was created via voice
                if note.wasVoiceInput {
                    Image(systemName: "mic.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Text(note.formattedDate)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotesListView()
    }
    .modelContainer(for: Note.self, inMemory: true)
}
