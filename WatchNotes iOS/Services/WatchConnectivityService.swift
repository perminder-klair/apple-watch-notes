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

    private let summarizationService = SummarizationService.shared
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
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("WCSession activation failed: \(error.localizedDescription)")
                return
            }

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
        case .statusUpdate:
            // Status updates come from iPhone to Watch, not the other way
            break
        case .summarizationResponse:
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
