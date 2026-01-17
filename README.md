# WatchNotes

A standalone Apple Watch notes app built with SwiftUI and SwiftData. Create and manage notes using keyboard input (dictation/scribble) or voice recording with real-time speech-to-text transcription.

## Features

- Create notes via keyboard (dictation, scribble, emoji) or voice recording
- Real-time speech-to-text transcription using Apple's Speech framework
- Persistent storage with SwiftData
- Edit and delete notes with swipe gestures
- Visual indicators for voice-created notes

## Requirements

- macOS Sonoma 14.0+
- Xcode 15.0+
- watchOS 10.0+ (deployment target)
- Apple Watch for device testing (simulator works for most features)

## Setup

1. Open `WatchNotes.xcodeproj` in Xcode
2. Select the "WatchNotes Watch App" scheme
3. Choose a Watch simulator or connected device
4. Build and run (Cmd+R)

For detailed setup instructions including creating the project from scratch, see [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md).

## Project Structure

```
WatchNotes Watch App/
├── WatchNotesApp.swift      # App entry point, SwiftData setup
├── Models/
│   └── Note.swift           # Data model (@Model)
└── Views/
    ├── ContentView.swift    # Navigation container
    ├── NotesListView.swift  # Main notes list
    ├── NoteEditorView.swift # Create/edit notes
    └── VoiceInputView.swift # Voice recording & transcription
```

## Permissions

The app requires these permissions (configured in Info.plist):
- **Microphone** - For voice note recording
- **Speech Recognition** - For converting speech to text
