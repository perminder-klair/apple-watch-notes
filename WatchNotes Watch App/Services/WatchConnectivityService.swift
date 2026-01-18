import Foundation
import WatchConnectivity
import SwiftData
import Combine

/// Service that handles communication between Apple Watch and iPhone
@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published private(set) var isPhoneReachable: Bool = false
    @Published private(set) var isAIAvailable: Bool = false
    @Published private(set) var aiStatusMessage: String = "Connecting to iPhone..."
    @Published private(set) var pendingNoteIds: Set<UUID> = []

    private var session: WCSession?
    private var modelContext: ModelContext?

    /// Callbacks for when summaries are received
    var onSummaryReceived: ((UUID, String) -> Void)?
    var onSummaryError: ((UUID, String) -> Void)?

    private override init() {
        super.init()
        setupSession()
    }

    /// Configure the model context for updating notes
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func setupSession() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity is not supported")
            aiStatusMessage = "Connectivity not supported"
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    /// Request a summary for a note from the iPhone
    /// - Parameters:
    ///   - noteId: The ID of the note to summarize
    ///   - content: The content of the note
    func requestSummary(for noteId: UUID, content: String) {
        guard let session = session else {
            onSummaryError?(noteId, "Watch connectivity not available")
            return
        }

        guard session.isReachable else {
            onSummaryError?(noteId, "iPhone not reachable")
            return
        }

        guard isAIAvailable else {
            onSummaryError?(noteId, aiStatusMessage)
            return
        }

        guard content.count >= kMinimumSummarizationLength else {
            onSummaryError?(noteId, "Note too short to summarize")
            return
        }

        pendingNoteIds.insert(noteId)

        let request = SummarizationRequest(noteId: noteId, noteContent: content)

        session.sendMessage(request.toDictionary(), replyHandler: { [weak self] _ in
            // Request acknowledged
        }) { [weak self] error in
            Task { @MainActor in
                self?.pendingNoteIds.remove(noteId)
                self?.onSummaryError?(noteId, "Failed to send request: \(error.localizedDescription)")
            }
        }
    }

    /// Check if a summary request is pending for a note
    func isPending(noteId: UUID) -> Bool {
        pendingNoteIds.contains(noteId)
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("WCSession activation failed: \(error.localizedDescription)")
                aiStatusMessage = "Connection failed"
                return
            }

            updateConnectionState(session)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
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
            replyHandler(["received": true])
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            processIncomingMessage(userInfo)
        }
    }

    private func processIncomingMessage(_ message: [String: Any]) {
        guard let messageTypeRaw = message["messageType"] as? String,
              let messageType = NoteMessageType(rawValue: messageTypeRaw) else {
            return
        }

        switch messageType {
        case .summarizationResponse:
            if let response = SummarizationResponse.fromDictionary(message) {
                handleSummarizationResponse(response)
            }
        case .statusUpdate:
            if let status = ConnectionStatus.fromDictionary(message) {
                handleStatusUpdate(status)
            }
        case .summarizationRequest:
            // Requests go from Watch to iPhone, not the other way
            break
        }
    }

    private func handleSummarizationResponse(_ response: SummarizationResponse) {
        pendingNoteIds.remove(response.noteId)

        if response.success, let summary = response.summary {
            onSummaryReceived?(response.noteId, summary)
        } else if let error = response.error {
            onSummaryError?(response.noteId, error)
        }
    }

    private func handleStatusUpdate(_ status: ConnectionStatus) {
        isAIAvailable = status.isAIAvailable
        aiStatusMessage = status.statusMessage
    }

    private func updateConnectionState(_ session: WCSession) {
        isPhoneReachable = session.isReachable

        if !session.isReachable {
            aiStatusMessage = "iPhone not connected"
        }
    }
}
