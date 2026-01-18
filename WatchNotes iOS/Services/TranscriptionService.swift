import Foundation
import Speech
import AVFoundation
import Combine

/// Service that uses Apple's Speech framework to transcribe audio from the Watch
@MainActor
final class TranscriptionService: ObservableObject {
    static let shared = TranscriptionService()

    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var statusMessage: String = "Checking speech recognition..."

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.current)

    private init() {
        checkAvailability()
    }

    /// Check if speech recognition is available
    func checkAvailability() {
        guard let recognizer = speechRecognizer else {
            isAvailable = false
            statusMessage = "Speech recognition not supported for current locale"
            return
        }

        if recognizer.isAvailable {
            isAvailable = true
            statusMessage = "Speech recognition ready"
        } else {
            isAvailable = false
            statusMessage = "Speech recognition unavailable"
        }
    }

    /// Request speech recognition authorization
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    switch status {
                    case .authorized:
                        self.isAvailable = true
                        self.statusMessage = "Speech recognition ready"
                        continuation.resume(returning: true)
                    case .denied:
                        self.isAvailable = false
                        self.statusMessage = "Speech recognition denied"
                        continuation.resume(returning: false)
                    case .restricted:
                        self.isAvailable = false
                        self.statusMessage = "Speech recognition restricted"
                        continuation.resume(returning: false)
                    case .notDetermined:
                        self.isAvailable = false
                        self.statusMessage = "Speech recognition not determined"
                        continuation.resume(returning: false)
                    @unknown default:
                        self.isAvailable = false
                        self.statusMessage = "Speech recognition unknown status"
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    /// Transcribe audio data received from the Watch
    /// - Parameter audioData: The audio data to transcribe (M4A/AAC format)
    /// - Returns: The transcribed text
    /// - Throws: TranscriptionError if transcription fails
    func transcribe(_ audioData: Data) async throws -> String {
        // Ensure authorization
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus != .authorized {
            let authorized = await requestAuthorization()
            if !authorized {
                throw TranscriptionError.notAuthorized
            }
        }

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }

        // Write audio data to a temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        do {
            try audioData.write(to: tempURL)
        } catch {
            throw TranscriptionError.audioFileError(error.localizedDescription)
        }

        // Clean up temp file when done
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        // Create recognition request from the audio file
        let request = SFSpeechURLRecognitionRequest(url: tempURL)
        request.shouldReportPartialResults = false

        // Perform transcription
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: TranscriptionError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let result = result else {
                    continuation.resume(throwing: TranscriptionError.noResult)
                    return
                }

                if result.isFinal {
                    let transcription = result.bestTranscription.formattedString
                    if transcription.isEmpty {
                        continuation.resume(throwing: TranscriptionError.emptyTranscription)
                    } else {
                        continuation.resume(returning: transcription)
                    }
                }
            }
        }
    }
}

/// Errors that can occur during transcription
enum TranscriptionError: LocalizedError {
    case notAuthorized
    case recognizerUnavailable
    case audioFileError(String)
    case recognitionFailed(String)
    case noResult
    case emptyTranscription

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .recognizerUnavailable:
            return "Speech recognizer is unavailable"
        case .audioFileError(let reason):
            return "Audio file error: \(reason)"
        case .recognitionFailed(let reason):
            return "Recognition failed: \(reason)"
        case .noResult:
            return "No transcription result"
        case .emptyTranscription:
            return "No speech detected in recording"
        }
    }
}
