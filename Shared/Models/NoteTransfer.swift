import Foundation

/// Message types for Watch ↔ iPhone communication
enum NoteMessageType: String, Codable {
    case summarizationRequest = "summarization_request"
    case summarizationResponse = "summarization_response"
    case statusUpdate = "status_update"
    case transcriptionRequest = "transcription_request"
    case transcriptionResponse = "transcription_response"
}

/// Request from Watch to iPhone for note summarization
struct SummarizationRequest: Codable {
    let messageType: NoteMessageType
    let noteId: UUID
    let noteContent: String
    let timestamp: Date

    init(noteId: UUID, noteContent: String) {
        self.messageType = .summarizationRequest
        self.noteId = noteId
        self.noteContent = noteContent
        self.timestamp = Date()
    }

    /// Convert to dictionary for WatchConnectivity message
    func toDictionary() -> [String: Any] {
        return [
            "messageType": messageType.rawValue,
            "noteId": noteId.uuidString,
            "noteContent": noteContent,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }

    /// Create from dictionary received via WatchConnectivity
    static func fromDictionary(_ dict: [String: Any]) -> SummarizationRequest? {
        guard let messageTypeRaw = dict["messageType"] as? String,
              let messageType = NoteMessageType(rawValue: messageTypeRaw),
              messageType == .summarizationRequest,
              let noteIdString = dict["noteId"] as? String,
              let noteId = UUID(uuidString: noteIdString),
              let noteContent = dict["noteContent"] as? String,
              let _ = dict["timestamp"] as? TimeInterval else {
            return nil
        }

        let request = SummarizationRequest(noteId: noteId, noteContent: noteContent)
        return request
    }
}

/// Response from iPhone to Watch with generated summary
struct SummarizationResponse: Codable {
    let messageType: NoteMessageType
    let noteId: UUID
    let summary: String?
    let error: String?
    let generatedAt: Date
    let success: Bool

    init(noteId: UUID, summary: String) {
        self.messageType = .summarizationResponse
        self.noteId = noteId
        self.summary = summary
        self.error = nil
        self.generatedAt = Date()
        self.success = true
    }

    init(noteId: UUID, error: String) {
        self.messageType = .summarizationResponse
        self.noteId = noteId
        self.summary = nil
        self.error = error
        self.generatedAt = Date()
        self.success = false
    }

    /// Convert to dictionary for WatchConnectivity message
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "messageType": messageType.rawValue,
            "noteId": noteId.uuidString,
            "generatedAt": generatedAt.timeIntervalSince1970,
            "success": success
        ]
        if let summary = summary {
            dict["summary"] = summary
        }
        if let error = error {
            dict["error"] = error
        }
        return dict
    }

    /// Create from dictionary received via WatchConnectivity
    static func fromDictionary(_ dict: [String: Any]) -> SummarizationResponse? {
        guard let messageTypeRaw = dict["messageType"] as? String,
              let messageType = NoteMessageType(rawValue: messageTypeRaw),
              messageType == .summarizationResponse,
              let noteIdString = dict["noteId"] as? String,
              let noteId = UUID(uuidString: noteIdString),
              let generatedAtInterval = dict["generatedAt"] as? TimeInterval,
              let success = dict["success"] as? Bool else {
            return nil
        }

        // generatedAt is validated but the actual timestamp comes from the initializer
        _ = Date(timeIntervalSince1970: generatedAtInterval)

        if success, let summary = dict["summary"] as? String {
            return SummarizationResponse(noteId: noteId, summary: summary)
        } else if let error = dict["error"] as? String {
            return SummarizationResponse(noteId: noteId, error: error)
        }

        return nil
    }
}

/// Connection status update message
struct ConnectionStatus: Codable {
    let messageType: NoteMessageType
    let isAIAvailable: Bool
    let statusMessage: String
    let timestamp: Date

    init(isAIAvailable: Bool, statusMessage: String) {
        self.messageType = .statusUpdate
        self.isAIAvailable = isAIAvailable
        self.statusMessage = statusMessage
        self.timestamp = Date()
    }

    func toDictionary() -> [String: Any] {
        return [
            "messageType": messageType.rawValue,
            "isAIAvailable": isAIAvailable,
            "statusMessage": statusMessage,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }

    static func fromDictionary(_ dict: [String: Any]) -> ConnectionStatus? {
        guard let messageTypeRaw = dict["messageType"] as? String,
              let messageType = NoteMessageType(rawValue: messageTypeRaw),
              messageType == .statusUpdate,
              let isAIAvailable = dict["isAIAvailable"] as? Bool,
              let statusMessage = dict["statusMessage"] as? String else {
            return nil
        }

        return ConnectionStatus(isAIAvailable: isAIAvailable, statusMessage: statusMessage)
    }
}

/// Minimum content length required for summarization
let kMinimumSummarizationLength = 50

// MARK: - Transcription Messages

/// Request from Watch to iPhone for audio transcription
struct TranscriptionRequest: Codable {
    let messageType: NoteMessageType
    let requestId: UUID
    let audioData: Data
    let timestamp: Date

    init(requestId: UUID = UUID(), audioData: Data) {
        self.messageType = .transcriptionRequest
        self.requestId = requestId
        self.audioData = audioData
        self.timestamp = Date()
    }

    /// Convert to dictionary for WatchConnectivity message
    func toDictionary() -> [String: Any] {
        return [
            "messageType": messageType.rawValue,
            "requestId": requestId.uuidString,
            "audioData": audioData.base64EncodedString(),
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }

    /// Create from dictionary received via WatchConnectivity
    static func fromDictionary(_ dict: [String: Any]) -> TranscriptionRequest? {
        guard let messageTypeRaw = dict["messageType"] as? String,
              let messageType = NoteMessageType(rawValue: messageTypeRaw),
              messageType == .transcriptionRequest,
              let requestIdString = dict["requestId"] as? String,
              let requestId = UUID(uuidString: requestIdString),
              let audioDataBase64 = dict["audioData"] as? String,
              let audioData = Data(base64Encoded: audioDataBase64) else {
            return nil
        }

        return TranscriptionRequest(requestId: requestId, audioData: audioData)
    }
}

/// Response from iPhone to Watch with transcription result
struct TranscriptionResponse: Codable {
    let messageType: NoteMessageType
    let requestId: UUID
    let transcription: String?
    let error: String?
    let success: Bool

    init(requestId: UUID, transcription: String) {
        self.messageType = .transcriptionResponse
        self.requestId = requestId
        self.transcription = transcription
        self.error = nil
        self.success = true
    }

    init(requestId: UUID, error: String) {
        self.messageType = .transcriptionResponse
        self.requestId = requestId
        self.transcription = nil
        self.error = error
        self.success = false
    }

    /// Convert to dictionary for WatchConnectivity message
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "messageType": messageType.rawValue,
            "requestId": requestId.uuidString,
            "success": success
        ]
        if let transcription = transcription {
            dict["transcription"] = transcription
        }
        if let error = error {
            dict["error"] = error
        }
        return dict
    }

    /// Create from dictionary received via WatchConnectivity
    static func fromDictionary(_ dict: [String: Any]) -> TranscriptionResponse? {
        guard let messageTypeRaw = dict["messageType"] as? String,
              let messageType = NoteMessageType(rawValue: messageTypeRaw),
              messageType == .transcriptionResponse,
              let requestIdString = dict["requestId"] as? String,
              let requestId = UUID(uuidString: requestIdString),
              let success = dict["success"] as? Bool else {
            return nil
        }

        if success, let transcription = dict["transcription"] as? String {
            return TranscriptionResponse(requestId: requestId, transcription: transcription)
        } else if let error = dict["error"] as? String {
            return TranscriptionResponse(requestId: requestId, error: error)
        }

        return nil
    }
}
