import Foundation
import FoundationModels
import Combine

/// Service that uses Apple's Foundation Models (on-device LLM) to generate note summaries
@MainActor
final class SummarizationService: ObservableObject {
    static let shared = SummarizationService()

    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var statusMessage: String = "Checking AI availability..."

    private let model = SystemLanguageModel.default

    private init() {
        checkAvailability()
    }

    /// Check if Apple Intelligence / Foundation Models is available on this device
    func checkAvailability() {
        switch model.availability {
        case .available:
            isAvailable = true
            statusMessage = "Apple Intelligence ready"
        case .unavailable(.deviceNotEligible):
            isAvailable = false
            statusMessage = "Device doesn't support Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            isAvailable = false
            statusMessage = "Enable Apple Intelligence in Settings"
        case .unavailable(.modelNotReady):
            isAvailable = false
            statusMessage = "AI model is downloading..."
        case .unavailable:
            isAvailable = false
            statusMessage = "Apple Intelligence unavailable"
        }
    }

    /// Generate a summary for the given note content
    /// - Parameter content: The note content to summarize
    /// - Returns: The generated summary
    /// - Throws: SummarizationError if summarization fails
    func summarize(_ content: String) async throws -> String {
        // Re-check availability before each request
        checkAvailability()

        guard isAvailable else {
            throw SummarizationError.aiNotAvailable(statusMessage)
        }

        guard content.count >= kMinimumSummarizationLength else {
            throw SummarizationError.contentTooShort
        }

        // Create a session with instructions for summarization
        let session = LanguageModelSession(instructions: """
            You are a concise note summarizer. Given note content, provide a brief 1-2 sentence summary
            that captures the key points. Be direct and informative. Do not use phrases like
            "This note is about" or "The note discusses". Just state the main point directly.
            """)

        let prompt = "Summarize this note:\n\n\(content)"

        do {
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw SummarizationError.generationFailed(error.localizedDescription)
        }
    }
}

/// Errors that can occur during summarization
enum SummarizationError: LocalizedError {
    case aiNotAvailable(String)
    case contentTooShort
    case contentTooLong
    case contentFlagged
    case sessionCreationFailed
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .aiNotAvailable(let reason):
            return "AI not available: \(reason)"
        case .contentTooShort:
            return "Note is too short to summarize (minimum \(kMinimumSummarizationLength) characters)"
        case .contentTooLong:
            return "Note is too long to process"
        case .contentFlagged:
            return "Content could not be processed"
        case .sessionCreationFailed:
            return "Failed to initialize AI session"
        case .generationFailed(let reason):
            return "Summary generation failed: \(reason)"
        }
    }
}
