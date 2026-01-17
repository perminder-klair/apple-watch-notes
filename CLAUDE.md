# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WatchNotes is a standalone Apple Watch notes app built with SwiftUI and SwiftData. It allows users to create, edit, and manage notes using keyboard input (dictation/scribble) or voice recording with real-time speech-to-text transcription.

## Build Commands

```bash
# Build the project
xcodebuild -project WatchNotes.xcodeproj -scheme "WatchNotes Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build

# Run on simulator
xcodebuild -project WatchNotes.xcodeproj -scheme "WatchNotes Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build
open -a Simulator

# Clean build
xcodebuild -project WatchNotes.xcodeproj -scheme "WatchNotes Watch App" clean
```

## Architecture

### Data Flow
- **SwiftData** handles persistence via `@Model` (Note.swift) and `.modelContainer(for:)` in the app entry point
- Views access data through `@Query` (automatic fetching) and `@Environment(\.modelContext)` (for mutations)
- SwiftData auto-saves changes; no explicit save calls needed

### View Hierarchy
```
WatchNotesApp (entry point, sets up modelContainer)
└── ContentView (NavigationStack wrapper)
    └── NotesListView (main list, @Query for notes)
        ├── NoteEditorView (create/edit notes)
        │   └── VoiceInputView (speech-to-text)
        └── NoteRowView (list item display)
```

### Input Modes
The app supports two input modes defined in `InputMode` enum:
- `keyboard`: Standard TextField with watchOS dictation/scribble
- `voice`: Dedicated recording view using Speech framework (SFSpeechRecognizer) and AVFoundation

### Key Patterns
- Views use `@Environment(\.dismiss)` for navigation back
- VoiceInputView uses a callback closure `onTranscription: (String) -> Void` to pass transcribed text to parent
- Note model uses computed properties (`preview`, `displayTitle`, `formattedDate`) for display logic

## Requirements

- Xcode 15+
- watchOS 10+ deployment target
- Info.plist requires `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` for voice features
