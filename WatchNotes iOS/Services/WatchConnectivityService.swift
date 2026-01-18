import Foundation
import WatchConnectivity
import Combine

/// Service that handles communication between iPhone and Apple Watch
@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published private(set) var isWatchReachable: Bool = false
    @Published private(set) var isWatchPaired: Bool = false
    @Published private(set) var isWatchAppInstalled: Bool = false
    @Published private(set) var lastSummarizationRequest: Date?
    @Published private(set) var pendingRequestCount: Int = 0
    @Published private(set) var lastTranscriptionRequest: Date?
    @Published private(set) var pendingTranscriptionCount: Int = 0

    /// Tracks in-flight transcription request IDs to prevent duplicate processing
    private var pendingTranscriptionIds = Set<UUID>()

    private let summarizationService = SummarizationService.shared
    private let transcriptionService = TranscriptionService.shared
    private var session: WCSession?

    private override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity is not supported on this device")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    /// Send AI status update to Watch
    func sendStatusUpdate() {
        guard let session = session, session.isReachable else { return }

        let status = ConnectionStatus(
            isAIAvailable: summarizationService.isAvailable,
            statusMessage: summarizationService.statusMessage
        )

        session.sendMessage(status.toDictionary(), replyHandler: nil) { error in
            print("Error sending status update: \(error.localizedDescription)")
        }
    }

    /// Process a summarization request from the Watch
    private func handleSummarizationRequest(_ request: SummarizationRequest) {
        Task { @MainActor in
            pendingRequestCount += 1
            lastSummarizationRequest = Date()

            do {
                let summary = try await summarizationService.summarize(request.noteContent)
                let response = SummarizationResponse(noteId: request.noteId, summary: summary)
                sendResponse(response)
            } catch {
                let errorMessage = (error as? SummarizationError)?.errorDescription ?? error.localizedDescription
                let response = SummarizationResponse(noteId: request.noteId, error: errorMessage)
                sendResponse(response)
            }

            pendingRequestCount -= 1
        }
    }

    /// Send response back to Watch
    private func sendResponse(_ response: SummarizationResponse) {
        guard let session = session else { return }

        // Use transferUserInfo for guaranteed delivery even if Watch becomes unreachable
        session.transferUserInfo(response.toDictionary())

        // Also try to send immediately if reachable
        if session.isReachable {
            session.sendMessage(response.toDictionary(), replyHandler: nil) { error in
                print("Error sending response: \(error.localizedDescription)")
            }
        }
    }

    /// Process a transcription request from the Watch
    private func handleTranscriptionRequest(_ request: TranscriptionRequest) {
        // Prevent duplicate processing (WatchConnectivity can deliver duplicates)
        guard !pendingTranscriptionIds.contains(request.requestId) else {
            print("Ignoring duplicate transcription request: \(request.requestId)")
            return
        }
        pendingTranscriptionIds.insert(request.requestId)

        Task { @MainActor in
            defer { pendingTranscriptionIds.remove(request.requestId) }

            pendingTranscriptionCount += 1
            lastTranscriptionRequest = Date()

            do {
                let transcription = try await transcriptionService.transcribe(request.audioData)
                let response = TranscriptionResponse(requestId: request.requestId, transcription: transcription)
                sendTranscriptionResponse(response)
            } catch {
                let errorMessage = (error as? TranscriptionError)?.errorDescription ?? error.localizedDescription
                let response = TranscriptionResponse(requestId: request.requestId, error: errorMessage)
                sendTranscriptionResponse(response)
            }

            pendingTranscriptionCount -= 1
        }
    }

    /// Send transcription response back to Watch
    private func sendTranscriptionResponse(_ response: TranscriptionResponse) {
        guard let session = session else { return }

        // Use transferUserInfo for guaranteed delivery even if Watch becomes unreachable
        session.transferUserInfo(response.toDictionary())

        // Also try to send immediately if reachable
        if session.isReachable {
            session.sendMessage(response.toDictionary(), replyHandler: nil) { error in
                print("Error sending transcription response: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("WCSession activation failed: \(error.localizedDescription)")
                return
            }

            // Diagnostic logging for WatchConnectivity debugging
            print("WCSession activated - state: \(activationState.rawValue)")
            print("  isPaired: \(session.isPaired)")
            print("  isWatchAppInstalled: \(session.isWatchAppInstalled)")
            print("  isReachable: \(session.isReachable)")

            updateConnectionState(session)

            // Send initial status update
            if activationState == .activated {
                sendStatusUpdate()
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        // Reactivate session
        Task { @MainActor in
            self.session?.activate()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateConnectionState(session)

            // Send status update when Watch becomes reachable
            if session.isReachable {
                sendStatusUpdate()
            }
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateConnectionState(session)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            processIncomingMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            processIncomingMessage(message)

            // Acknowledge receipt
            replyHandler(["received": true])
        }
    }

    /// Handle incoming file transfers from Watch (used for audio data which exceeds sendMessage size limits)
    /// CRITICAL: Must read file data synchronously before returning - system may delete the file after delegate returns
    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        // Validate metadata synchronously
        guard let metadata = file.metadata,
              let messageTypeRaw = metadata["messageType"] as? String,
              messageTypeRaw == NoteMessageType.transcriptionRequest.rawValue,
              let requestIdString = metadata["requestId"] as? String,
              let requestId = UUID(uuidString: requestIdString) else {
            print("Invalid file transfer metadata received")
            return
        }

        // MUST read file data before returning - system may delete it after delegate returns
        let audioData: Data
        do {
            audioData = try Data(contentsOf: file.fileURL)
        } catch {
            print("Failed to read transferred audio file: \(error.localizedDescription)")
            Task { @MainActor in
                let response = TranscriptionResponse(requestId: requestId, error: "Failed to read audio file")
                self.sendTranscriptionResponse(response)
            }
            return
        }

        // Now safe to process asynchronously - we have the data in memory
        Task { @MainActor in
            let request = TranscriptionRequest(requestId: requestId, audioData: audioData)
            self.handleTranscriptionRequest(request)
        }
    }

    private func processIncomingMessage(_ message: [String: Any]) {
        guard let messageTypeRaw = message["messageType"] as? String,
              let messageType = NoteMessageType(rawValue: messageTypeRaw) else {
            print("Unknown message type received")
            return
        }

        switch messageType {
        case .summarizationRequest:
            if let request = SummarizationRequest.fromDictionary(message) {
                handleSummarizationRequest(request)
            }
        case .transcriptionRequest:
            if let request = TranscriptionRequest.fromDictionary(message) {
                handleTranscriptionRequest(request)
            }
        case .statusUpdate:
            // Status updates come from iPhone to Watch, not the other way
            break
        case .summarizationResponse, .transcriptionResponse:
            // Responses go from iPhone to Watch, not the other way
            break
        }
    }

    private func updateConnectionState(_ session: WCSession) {
        isWatchReachable = session.isReachable
        isWatchPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
    }
}
