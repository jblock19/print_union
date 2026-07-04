# Roadmap

## 1. Product Seed

- Preserve the existing modular flyer editor.
- Pin dependencies and initialize a GitHub repository.
- Document the shared template JSON contract.

## 2. Style Archetype Renderer

- Add a Gallery Ledger archetype inspired by strict black-and-white arts flyers.
- Represent divider lines, chips, QR slots, borders, and text boxes as editable objects.
- Keep copy as placeholders.

## 3. Local Style Importer

- Upload a flyer image.
- Normalize page bounds and aspect ratio.
- Extract palette, border, dividers, filled shapes, and major content rectangles.
- Generate style fingerprint JSON.

## 4. Editable Reconstruction

- Convert the style fingerprint into modular template elements.
- Render those elements in the editor.
- Add controls for background, grid, dividers, chips, spacing, and element visibility.

## 5. AI Enhancement

- Use AI to classify style families and suggest editable modules.
- Keep deterministic computer-vision geometry as the source of coordinates.
- Make AI advisory, not authoritative.

## 6. Cloud + Native

- Add Supabase for accounts, storage, template versions, and shared links.
- Add local-first macOS storage later with sync to the same template schema.
