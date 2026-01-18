//
//  VoiceInputView.swift
//  WatchNotes Watch App
//
//  This view provides dedicated voice input by recording audio on Watch
//  and sending it to iPhone for transcription via the Speech framework.
//

import SwiftUI
import AVFoundation

/// VoiceInputView handles audio recording and remote transcription
struct VoiceInputView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    /// Callback when transcription is complete
    let onTranscription: (String) -> Void

    // MARK: - State

    /// Current recording state
    @State private var isRecording = false

    /// Whether we're waiting for transcription from iPhone
    @State private var isTranscribing = false

    /// The transcribed text received from iPhone
    @State private var transcribedText = ""

    /// Error message if something goes wrong
    @State private var errorMessage: String?

    /// Whether we have microphone permission
    @State private var hasPermission = false

    /// Whether we're checking permissions
    @State private var isCheckingPermission = true

    /// Whether iPhone is reachable for transcription
    @State private var isPhoneReachable = false

    // MARK: - Audio Recording

    /// Audio recorder for capturing microphone input
    @State private var audioRecorder: AVAudioRecorder?

    /// URL where the recording is saved
    @State private var recordingURL: URL?

    /// Connectivity service for communicating with iPhone
    private let connectivityService = WatchConnectivityService.shared

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isCheckingPermission {
                    // Loading state while checking permissions
                    ProgressView()
                    Text("Checking permissions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let error = errorMessage {
                    // Error state
                    errorView(message: error)
                } else if !hasPermission {
                    // Permission denied state
                    permissionDeniedView
                } else if isTranscribing {
                    // Transcribing state (waiting for iPhone)
                    transcribingView
                } else {
                    // Main recording interface
                    recordingInterface
                }
            }
            .padding()
        }
        .navigationTitle("Voice Input")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkPermissions()
            setupTranscriptionCallback()
        }
        .onDisappear {
            // Stop recording if still active
            stopRecording()

            // CRITICAL: Clear callbacks to prevent updates to deallocated view
            connectivityService.clearTranscriptionCallbacks()

            // Deactivate audio session
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
        .onReceive(connectivityService.$isPhoneReachable) { reachable in
            isPhoneReachable = reachable
        }
    }

    // MARK: - Subviews

    /// Main recording interface
    private var recordingInterface: some View {
        VStack(spacing: 20) {
            // Connection status
            if !isPhoneReachable {
                connectionWarning
            }

            // Visual indicator
            recordingIndicator

            // Transcribed text preview
            if !transcribedText.isEmpty {
                transcribedTextView
            }

            // Record/Stop button
            recordButton

            // Done button (when we have text)
            if !transcribedText.isEmpty {
                doneButton
            }
        }
    }

    /// Warning shown when iPhone is not reachable
    private var connectionWarning: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("iPhone required for transcription")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.2))
        .cornerRadius(8)
    }

    /// View shown while waiting for transcription
    private var transcribingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Transcribing...")
                .font(.headline)

            Text("Sending audio to iPhone")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    /// Animated recording indicator
    private var recordingIndicator: some View {
        ZStack {
            // Outer pulsing circle (when recording)
            Circle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 80, height: 80)
                .scaleEffect(isRecording ? 1.2 : 1.0)
                .animation(
                    isRecording ?
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                        .default,
                    value: isRecording
                )

            // Inner circle
            Circle()
                .fill(isRecording ? Color.red : Color.gray)
                .frame(width: 60, height: 60)

            // Microphone icon
            Image(systemName: isRecording ? "mic.fill" : "mic")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
    }

    /// Shows the transcribed text
    private var transcribedTextView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Transcription:")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(transcribedText)
                .font(.body)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
    }

    /// Record/Stop toggle button
    private var recordButton: some View {
        Button {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        } label: {
            HStack {
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                Text(isRecording ? "Stop" : "Start Recording")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(isRecording ? .red : .blue)
        .disabled(!isPhoneReachable && !isRecording)
    }

    /// Done button to confirm and use the transcription
    private var doneButton: some View {
        Button {
            onTranscription(transcribedText)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "checkmark")
                Text("Use This Text")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }

    /// View shown when there's an error
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Error")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                errorMessage = nil
                isTranscribing = false
                checkPermissions()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    /// View shown when permission is denied
    private var permissionDeniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash")
                .font(.system(size: 40))
                .foregroundColor(.red)

            Text("Microphone Access Required")
                .font(.headline)

            Text("Please enable microphone access in Settings to use voice input.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Dismiss") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Permission Handling

    /// Checks for microphone permissions
    private func checkPermissions() {
        isCheckingPermission = true

        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                hasPermission = granted
                isCheckingPermission = false
            }
        }
    }

    // MARK: - Transcription Callback

    /// Set up the callback for receiving transcription results
    private func setupTranscriptionCallback() {
        connectivityService.onTranscriptionReceived = { (transcription: String) in
            DispatchQueue.main.async {
                self.isTranscribing = false
                self.transcribedText = transcription
            }
        }

        connectivityService.onTranscriptionError = { (error: String) in
            DispatchQueue.main.async {
                self.isTranscribing = false
                self.errorMessage = error
            }
        }
    }

    // MARK: - Recording Methods

    /// Starts audio recording
    private func startRecording() {
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            errorMessage = "Could not configure audio session: \(error.localizedDescription)"
            return
        }

        // Create recording URL
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        recordingURL = url

        // Configure recorder settings for good quality while keeping file size reasonable
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
        }
    }

    /// Stops recording and sends audio to iPhone for transcription
    private func stopRecording() {
        guard isRecording else { return }

        audioRecorder?.stop()
        isRecording = false

        // Deactivate audio session to release resources
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        // Send audio to iPhone for transcription
        guard let url = recordingURL else {
            errorMessage = "No recording found"
            return
        }

        do {
            let audioData = try Data(contentsOf: url)

            // Clean up the temp file
            try? FileManager.default.removeItem(at: url)

            // Check if iPhone is reachable
            guard isPhoneReachable else {
                errorMessage = "iPhone not connected. Please ensure your iPhone is nearby and the WatchNotes app is installed."
                return
            }

            // Send to iPhone for transcription
            isTranscribing = true
            connectivityService.requestTranscription(audioData: audioData)

        } catch {
            errorMessage = "Could not read recording: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VoiceInputView { text in
            print("Transcribed: \(text)")
        }
    }
}
