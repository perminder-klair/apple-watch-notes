# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WatchNotes is a standalone Apple Watch notes app built with SwiftUI and SwiftData. It allows users to create, edit, and manage notes using keyboard input (dictation/scribble) or voice recording with real-time speech-to-text transcription. Includes a companion iPhone app that provides AI-powered note summarization using Apple's Foundation Models framework.

## Build Commands

```bash
# Build Watch app
xcodebuild -project WatchNotes.xcodeproj -scheme "WatchNotes Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' build

# Build iOS app
xcodebuild -project WatchNotes.xcodeproj -scheme "WatchNotes iOS" -destination 'platform=iOS Simulator,name=iPhone 17' build

# Clean build
xcodebuild -project WatchNotes.xcodeproj clean
```

**Note:** The Watch app may fail to build on simulator due to the Speech framework. Use a real device for full testing. WatchConnectivity also requires physical devices.

## Architecture

### Data Flow
- **SwiftData** handles persistence via `@Model` (Note.swift) and `.modelContainer(for:)` in the app entry point
- Views access data through `@Query` (automatic fetching) and `@Environment(\.modelContext)` (for mutations)
- SwiftData auto-saves changes; no explicit save calls needed
- **WatchConnectivity** handles communication between Watch and iPhone for AI summarization

### View Hierarchy (Watch)
```
WatchNotesApp (entry point, sets up modelContainer)
└── ContentView (NavigationStack wrapper)
    └── NotesListView (main list, @Query for notes)
        ├── NoteDetailView (view note + summary)
        │   └── NoteEditorView (edit note)
        │       └── VoiceInputView (speech-to-text)
        └── NoteRowView (list item with summary indicator)
```

### View Hierarchy (iOS)
```
WatchNotesIOSApp (entry point)
└── ContentView (status dashboard)
    ├── AI availability status
    ├── Watch connection status
    └── Activity/request status
```

### Input Modes
The app supports two input modes defined in `InputMode` enum:
- `keyboard`: Standard TextField with watchOS dictation/scribble
- `voice`: Dedicated recording view using Speech framework (SFSpeechRecognizer) and AVFoundation

### Key Patterns
- Views use `@Environment(\.dismiss)` for navigation back
- VoiceInputView uses a callback closure `onTranscription: (String) -> Void` to pass transcribed text to parent
- Note model uses computed properties (`preview`, `displayTitle`, `formattedDate`) for display logic
- WatchConnectivityService on both platforms handles message passing
- SummarizationService on iOS wraps Foundation Models for AI summaries

### AI Summarization Flow
1. User taps "Generate Summary" on NoteDetailView (Watch)
2. Watch sends SummarizationRequest via WatchConnectivity
3. iPhone receives request, generates summary via Foundation Models
4. iPhone sends SummarizationResponse back to Watch
5. Watch updates Note model with summary

## Requirements

- Xcode 15+
- watchOS 10+ deployment target (Watch app)
- iOS 26.0+ deployment target (iPhone app, for Foundation Models)
- Apple Intelligence enabled on iPhone for summarization
- Physical devices recommended for WatchConnectivity testing
- Info.plist requires `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` for voice features
