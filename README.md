# WatchNotes

A standalone Apple Watch notes app built with SwiftUI and SwiftData. Create and manage notes using keyboard input (dictation/scribble) or voice recording with real-time speech-to-text transcription. Includes AI-powered note summarization via a companion iPhone app.

## Features

- Create notes via keyboard (dictation, scribble, emoji) or voice recording
- Real-time speech-to-text transcription using Apple's Speech framework
- **AI-powered note summarization** using Apple Intelligence (Foundation Models)
- Persistent storage with SwiftData
- Edit and delete notes with swipe gestures
- Visual indicators for voice-created notes and summary status

## Architecture

```
┌─────────────────────┐         WatchConnectivity         ┌─────────────────────┐
│   Apple Watch       │◄──────────────────────────────────►│      iPhone         │
│                     │                                    │                     │
│  Note + summary     │  1. Send note content              │  Foundation Models  │
│  stored locally     │  2. Receive AI summary             │  (on-device LLM)    │
│  via SwiftData      │                                    │                     │
└─────────────────────┘                                    └─────────────────────┘
```

## Requirements

- macOS Sonoma 14.0+
- Xcode 15.0+
- watchOS 10.0+ (Watch app deployment target)
- iOS 26.0+ (iPhone app deployment target, requires Apple Intelligence)
- Physical Apple Watch + iPhone pair for full functionality
- Apple Intelligence enabled on iPhone for summarization

## Setup

1. Open `WatchNotes.xcodeproj` in Xcode
2. Select the "WatchNotes Watch App" scheme for Watch development
3. Select the "WatchNotes iOS" scheme for iPhone app
4. Build and run on physical devices (WatchConnectivity requires real hardware)

## Build Commands

```bash
# Build Watch app (use real device or compatible simulator)
xcodebuild -project WatchNotes.xcodeproj \
  -scheme "WatchNotes Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' \
  build

# Build iOS app
xcodebuild -project WatchNotes.xcodeproj \
  -scheme "WatchNotes iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build

# Clean build
xcodebuild -project WatchNotes.xcodeproj clean
```

## Project Structure

```
WatchNotes/
├── Shared/
│   └── Models/
│       └── NoteTransfer.swift      # Watch↔iPhone message types
├── WatchNotes Watch App/
│   ├── WatchNotesApp.swift         # App entry point, SwiftData setup
│   ├── Info.plist                  # Permissions configuration
│   ├── Models/
│   │   └── Note.swift              # Data model with summary fields
│   ├── Services/
│   │   └── WatchConnectivityService.swift  # iPhone communication
│   └── Views/
│       ├── ContentView.swift       # Navigation container
│       ├── NotesListView.swift     # Main notes list
│       ├── NoteDetailView.swift    # Note view with summary
│       ├── NoteEditorView.swift    # Create/edit notes
│       └── VoiceInputView.swift    # Voice recording & transcription
└── WatchNotes iOS/
    ├── WatchNotesIOSApp.swift      # iPhone app entry point
    ├── Services/
    │   ├── SummarizationService.swift      # Foundation Models wrapper
    │   └── WatchConnectivityService.swift  # Watch communication
    └── Views/
        └── ContentView.swift       # Status dashboard
```

## Permissions

**Watch App (Info.plist):**
- **Microphone** - For voice note recording
- **Speech Recognition** - For converting speech to text

**iPhone App:**
- No additional permissions required (Foundation Models runs on-device)

## AI Summarization

The summarization feature requires:
1. An iPhone with Apple Intelligence enabled
2. iOS 26.0 or later
3. The WatchNotes iOS companion app installed
4. Watch and iPhone paired and connected

Notes must be at least 50 characters to be summarized. The summary is generated on-device using Apple's Foundation Models framework (3B parameter LLM).
