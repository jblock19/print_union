# Print Union

Print Union is a standalone Next.js seed for a product that turns uploaded flyer, poster, and notice styles into editable modular templates.

## Run

```bash
npm install
npm run dev
```

The app runs on `127.0.0.1:3000` by default. To use a specific port:

```bash
npm run dev -- --port 3030
```

## What Is Included

- The flyer editor page and global styles.
- Local browser persistence through `localStorage` and IndexedDB.
- Public flyer sample photos and Classifieds category icons.
- Starter architecture docs for style extraction and modular template JSON.
- A Swift-first starter under `apple/PrintUnion` with `PrintUnionCore` schema models and a native SwiftUI app shell.

## What Is Not Included

- The broader Classifieds app.
- Supabase integration.
- OCR, AI extraction, or uploaded-flyer-to-editable-template parsing.

## Product Direction

The first product milestone is a style importer:

1. Upload a flyer image.
2. Detect the visual system: background, borders, divider lines, spacing, element boxes, color palette, and type roles.
3. Convert that style fingerprint into editable template elements.
4. Render those elements in the existing flyer editor.

## Apple Starter

```bash
cd apple/PrintUnion
swift test
swift run PrintUnionApp
```

In Xcode, open `apple/PrintUnion/Package.swift`, choose the `PrintUnionApp` scheme and **My Mac**, then run. For the SwiftUI canvas, open `Sources/PrintUnionApp/ContentView.swift` and show the canvas with `Option+Cmd+Return`.
