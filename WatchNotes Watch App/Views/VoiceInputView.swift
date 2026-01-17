//
//  VoiceInputView.swift
//  WatchNotes Watch App
//
//  This view provides dedicated voice input using Apple's Speech framework.
//  It shows a visual recording interface and transcribes speech to text.
//

import SwiftUI
import Speech
import AVFoundation

/// VoiceInputView handles speech-to-text recording
struct VoiceInputView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    /// Callback when transcription is complete
    let onTranscription: (String) -> Void

    // MARK: - State

    /// Current recording state
    @State private var isRecording = false

    /// The transcribed text so far
    @State private var transcribedText = ""

    /// Error message if something goes wrong
    @State private var errorMessage: String?

    /// Whether we have microphone permission
    @State private var hasPermission = false

    /// Whether we're checking permissions
    @State private var isCheckingPermission = true

    // MARK: - Speech Recognition

    /// The speech recognizer for converting speech to text
    @State private var speechRecognizer: SFSpeechRecognizer?

    /// The current recognition request
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    /// The recognition task
    @State private var recognitionTask: SFSpeechRecognitionTask?

    /// Audio engine for capturing microphone input
    @State private var audioEngine = AVAudioEngine()

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
        }
        .onDisappear {
            stopRecording()
        }
    }

    // MARK: - Subviews

    /// Main recording interface
    private var recordingInterface: some View {
        VStack(spacing: 20) {
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

            Button("Open Settings") {
                // On watchOS, this opens the Watch Settings app
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    WKExtension.shared().openSystemURL(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Permission Handling

    /// Checks for speech recognition and microphone permissions
    private func checkPermissions() {
        isCheckingPermission = true

        // Initialize speech recognizer
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)

        // Check if speech recognition is available
        guard speechRecognizer?.isAvailable == true else {
            errorMessage = "Speech recognition is not available on this device."
            isCheckingPermission = false
            return
        }

        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    // Now check microphone permission
                    checkMicrophonePermission()
                case .denied, .restricted:
                    hasPermission = false
                    isCheckingPermission = false
                case .notDetermined:
                    hasPermission = false
                    isCheckingPermission = false
                @unknown default:
                    hasPermission = false
                    isCheckingPermission = false
                }
            }
        }
    }

    /// Checks microphone permission specifically
    private func checkMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                hasPermission = granted
                isCheckingPermission = false
            }
        }
    }

    // MARK: - Recording Methods

    /// Starts the speech recognition recording
    private func startRecording() {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Could not configure audio session: \(error.localizedDescription)"
            return
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Could not create recognition request."
            return
        }

        // Configure for real-time results
        recognitionRequest.shouldReportPartialResults = true

        // Get audio input
        let inputNode = audioEngine.inputNode

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                // Update transcribed text with the best transcription
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }

            if error != nil || (result?.isFinal == true) {
                self.stopRecording()
            }
        }

        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = "Could not start audio engine: \(error.localizedDescription)"
        }
    }

    /// Stops the speech recognition recording
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
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
