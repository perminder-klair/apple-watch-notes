# WatchNotes - Apple Watch Notes App Setup Guide

This guide will walk you through setting up the WatchNotes project in Xcode from scratch.

## Prerequisites

- **Mac** with macOS Sonoma 14.0 or later
- **Xcode 15.0** or later (download from Mac App Store)
- **Apple Watch** running watchOS 10.0+ (for testing on device)
- **Apple Developer Account** (free account works for simulator testing)

---

## Step 1: Create New Xcode Project

1. Open **Xcode**
2. Click **File → New → Project** (or press `⌘ + Shift + N`)
3. Select the **watchOS** tab at the top
4. Choose **App** and click **Next**

### Configure Project Settings:

| Setting | Value |
|---------|-------|
| Product Name | `WatchNotes` |
| Team | Your Apple ID (or None for simulator only) |
| Organization Identifier | `com.yourname` (e.g., `com.johndoe`) |
| Bundle Identifier | Auto-fills as `com.yourname.WatchNotes` |
| Interface | **SwiftUI** |
| Language | **Swift** |
| Storage | **SwiftData** ✅ |
| Watch-only App | **Yes** ✅ |

5. Click **Next**
6. Choose a location to save the project
7. Click **Create**

---

## Step 2: Replace Generated Files

Xcode creates some starter files. Replace them with the files from this folder:

### Files to Replace/Add:

```
WatchNotes/
└── WatchNotes Watch App/
    ├── WatchNotesApp.swift          ← Replace with provided file
    ├── ContentView.swift            ← Replace with Views/ContentView.swift
    ├── Info.plist                   ← Replace with provided file
    ├── Assets.xcassets/             ← Keep existing
    │
    ├── Models/                      ← Create this folder
    │   └── Note.swift               ← Add this file
    │
    └── Views/                       ← Create this folder
        ├── NotesListView.swift      ← Add this file
        ├── NoteEditorView.swift     ← Add this file
        └── VoiceInputView.swift     ← Add this file
```

### How to Add Files:

1. In Xcode's **Project Navigator** (left sidebar), right-click on `WatchNotes Watch App`
2. Select **New Group** → Name it `Models`
3. Right-click on `Models` → **Add Files to "WatchNotes"**
4. Select `Note.swift` from the provided files
5. Repeat for `Views` folder with the view files

### Important: Delete ContentView.swift from root

After adding the Views folder with ContentView.swift inside, delete the auto-generated ContentView.swift from the root level to avoid conflicts.

---

## Step 3: Configure Info.plist Permissions

The app needs permissions for microphone and speech recognition.

1. Select your project in the navigator (top blue icon)
2. Select the **WatchNotes Watch App** target
3. Go to the **Info** tab
4. Under **Custom iOS Target Properties**, add these keys:

| Key | Type | Value |
|-----|------|-------|
| Privacy - Microphone Usage Description | String | `WatchNotes needs microphone access to record voice notes.` |
| Privacy - Speech Recognition Usage Description | String | `WatchNotes uses speech recognition to convert your voice recordings into text.` |

**Note:** These may already be in the provided Info.plist file.

---

## Step 4: Build & Run

### On Simulator:

1. In the top toolbar, select a Watch simulator (e.g., `Apple Watch Series 9 (45mm)`)
2. Press **⌘ + R** or click the **Play** button
3. Wait for the simulator to boot and the app to install

### On Physical Apple Watch:

1. Connect your iPhone to your Mac
2. Ensure your Watch is paired with the iPhone
3. Select your Watch from the device list
4. Press **⌘ + R** to build and install
5. You may need to trust the developer certificate on your Watch:
   - On iPhone: **Settings → General → VPN & Device Management**
   - Tap your developer app and trust it

---

## Step 5: Test the App

### Testing Keyboard Input:
1. Tap the **+** button
2. Select **"Type Note"**
3. Tap the text field - this opens watchOS input options:
   - **Dictation** (microphone icon)
   - **Scribble** (draw letters with finger)
   - **Emoji**
4. Enter some text and tap **Save**

### Testing Voice Input:
1. Tap the **+** button
2. Select **"Voice Note"**
3. Tap **"Start Recording"**
4. Speak your note
5. Tap **"Stop"** when done
6. Review the transcription
7. Tap **"Use This Text"** to save

### Testing Note Management:
- Tap any note to edit it
- Swipe left on a note to delete it
- Notes persist between app launches

---

## Project Structure Explained

```
WatchNotes Watch App/
├── WatchNotesApp.swift      # App entry point, sets up SwiftData
├── Models/
│   └── Note.swift           # Data model for notes (SwiftData)
├── Views/
│   ├── ContentView.swift    # Root navigation container
│   ├── NotesListView.swift  # Main list of all notes
│   ├── NoteEditorView.swift # Create/edit notes with text
│   └── VoiceInputView.swift # Voice recording & transcription
└── Assets.xcassets/         # App icons and colors
```

---

## Key Technologies Used

| Technology | Purpose |
|------------|---------|
| **SwiftUI** | Modern declarative UI framework |
| **SwiftData** | Apple's new data persistence framework |
| **Speech Framework** | Converts speech to text |
| **AVFoundation** | Audio recording capabilities |

---

## Troubleshooting

### "Speech recognition unavailable" error
- Ensure your device/simulator has internet connectivity
- Speech recognition requires Apple's servers for processing
- Try restarting the simulator

### Notes not persisting
- Check that SwiftData is properly configured in WatchNotesApp.swift
- Clean the build folder: **Product → Clean Build Folder** (⌘ + Shift + K)

### Microphone permission not showing
- Delete the app from the simulator/watch
- Clean build folder and rebuild
- Ensure Info.plist keys are correct

### Build errors with SwiftData
- Ensure you're using Xcode 15+ and targeting watchOS 10+
- Check that `@Model` macro is properly applied to Note class

---

## Next Steps & Enhancements

Here are some features you could add:

1. **Search** - Add a search bar to find notes
2. **Categories/Tags** - Organize notes into folders
3. **Complications** - Show note count on watch face
4. **Haptic Feedback** - Add vibration for save confirmation
5. **Rich Text** - Support bold, italic formatting
6. **Export** - Share notes via iMessage

---

## Need Help?

- [Apple watchOS Development Documentation](https://developer.apple.com/documentation/watchos)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Speech Framework Guide](https://developer.apple.com/documentation/speech)

Happy coding! 🎉
