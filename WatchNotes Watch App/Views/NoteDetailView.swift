import SwiftUI
import SwiftData

/// View that displays note content and AI-generated summary
struct NoteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var connectivityService = WatchConnectivityService.shared

    @Bindable var note: Note

    @State private var isGeneratingSummary = false
    @State private var summaryError: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Note Title
                if !note.title.isEmpty {
                    Text(note.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                // Note Content
                Text(note.content)
                    .font(.body)

                // Metadata
                HStack {
                    if note.wasVoiceInput {
                        Image(systemName: "waveform")
                            .foregroundStyle(.secondary)
                    }
                    Text(note.formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                Divider()
                    .padding(.vertical, 8)

                // Summary Section
                summarySection
            }
            .padding(.horizontal)
        }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: NoteEditorView(existingNote: note)) {
                    Image(systemName: "pencil")
                }
            }
        }
        .alert("Summary Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(summaryError ?? "An unknown error occurred")
        }
        .onAppear {
            setupSummaryCallbacks()
        }
    }

    @ViewBuilder
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("AI Summary")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)

                Spacer()

                if note.hasSummary && note.isSummaryOutdated {
                    Text("Outdated")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            if isGeneratingSummary || connectivityService.isPending(noteId: note.id) {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let summary = note.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                Text("No summary yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Generate Summary Button
            if !isGeneratingSummary && !connectivityService.isPending(noteId: note.id) {
                generateButton
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.purple.opacity(0.1))
        )
    }

    @ViewBuilder
    private var generateButton: some View {
        Button {
            generateSummary()
        } label: {
            HStack {
                Image(systemName: note.hasSummary ? "arrow.clockwise" : "sparkles")
                Text(note.hasSummary ? "Regenerate" : "Generate Summary")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.purple)
        .disabled(!canGenerateSummary)
    }

    private var canGenerateSummary: Bool {
        connectivityService.isPhoneReachable &&
        connectivityService.isAIAvailable &&
        note.canBeSummarized
    }

    private func generateSummary() {
        isGeneratingSummary = true
        summaryError = nil

        connectivityService.requestSummary(for: note.id, content: note.content)
    }

    private func setupSummaryCallbacks() {
        connectivityService.onSummaryReceived = { [self] noteId, summary in
            if noteId == note.id {
                isGeneratingSummary = false
                note.updateSummary(summary)
            }
        }

        connectivityService.onSummaryError = { [self] noteId, error in
            if noteId == note.id {
                isGeneratingSummary = false
                summaryError = error
                showError = true
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Note.self, configurations: config)
    let note = Note(
        content: "This is a sample note with enough content to be summarized. It contains more than fifty characters.",
        title: "Sample Note"
    )
    container.mainContext.insert(note)

    return NavigationStack {
        NoteDetailView(note: note)
    }
    .modelContainer(container)
}
