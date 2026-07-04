# Apple Architecture

Print Union is shifting toward a Swift-first product: macOS and iPadOS as the primary creation surfaces, with web kept as a schema/prototype/reference path.

## Why Native First

- Print workflows benefit from native file import, drag/drop, PDF generation, and print dialogs.
- macOS supports a workstation-style layout: source, canvas, inspector, and setup panels.
- iPadOS can make the Style Map feel like a tactile paste-up table with touch and Pencil.
- Apple Vision, Core Image, Core Graphics, PDFKit, and Accelerate can cover much of the local extraction/export foundation.

## Package Layout

```text
apple/PrintUnion
  Package.swift
  Sources/PrintUnionCore
  Sources/PrintUnionApp
  Tests/PrintUnionCoreTests
```

`PrintUnionCore` owns the portable schema:

- print formats
- invitation intents
- content roles
- style fingerprints
- editable elements
- setup ambiguities
- export settings

`PrintUnionApp` is the first native shell. It is intentionally small: sidebar, print canvas preview, and inspector. The next work should expand it into the Style Map setup flow.

## AI/API Shape

The native app should not store provider API keys. It should send uploads, measured geometry, or normalized images to a backend endpoint that calls AI services and returns Print Union JSON.

```text
Swift app
  -> local Vision/Core Image geometry
  -> backend AI endpoint
  -> structured template proposal
  -> Style Map review
  -> editable print document
```

## Next Native Milestones

1. Make `PrintUnionCore` the source of truth for the current web schema too.
2. Build real file import and source preview.
3. Build the Style Map setup page natively.
4. Add basic PDF/PNG export with safe margins and crop marks.
5. Add Apple Vision/Core Image measurement passes.
