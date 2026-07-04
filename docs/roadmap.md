# Roadmap

## 1. Product Contract

- Define the Print Union document schema in code.
- Preserve the existing flyer content model as semantic public-invitation roles.
- Include print constraints from the start: paper size, bleed, safe margin, crop marks, grayscale/photocopy preview.

## 2. Print Foundation

- Add real print document controls: Letter, A4, Tabloid, half-letter handbill, and 4:5 poster.
- Add basic PDF/PNG export early so the editor is accountable to print output.
- Add safe-area, contrast, and QR/margin warnings.

## 3. Handbuilt Archetypes As JSON

- Build Gallery Ledger, Pasteup Zine, and Community Notice as real editable JSON templates.
- Encode typographic and print logic, not just vibes.
- Use function-led variants such as Open Call, Public Meeting, Workshop Sheet, and Mutual Aid Notice.

## 4. Modular Renderer / Editor

- Refactor the current flyer page to render from the Print Union document schema.
- Support background, texture, border, divider, guide, text, chip, image placeholder, QR, logo/mark, handwritten mark, and group elements.
- Keep editing tactile and print-object-like rather than form-only.

## 5. Style Map Setup Page

- Upload/reference preview with overlays.
- Proposed element list grouped by role and hierarchy.
- Rename, remove, merge, split, group, and mark editable/reference.
- Ask human questions: what must change, what should remain atmosphere, what matters most in print.

## 6. Python / OpenCV Geometry

- Normalize image bounds and deskew.
- Detect borders, dividers, filled blocks, palette, texture, text-region boxes, QR-like regions, and spacing.
- Produce measured geometry JSON.

## 7. AI Interpretation

- Classify style family, public-invitation intent, element roles, groupings, typography roles, and ambiguities.
- Feed AI the source image, measured geometry, archetype list, and Print Union schema.
- Use AI for meaning; keep geometry as the source of coordinates.

## 8. Reconstruction

- Combine archetype defaults, measured geometry, AI interpretation, and Style Map user edits into editable template JSON.
- Render the result in the modular editor.

## 9. Visual Diff Loop

- Render the template to an image.
- Compare reconstruction to the source with CV metrics.
- Use AI for qualitative critique: missing dividers, wrong hierarchy, background mismatch, spacing drift.

## 10. Deep Print Export

- Print-ready PDF and PNG.
- Crop marks, multi-up handbills, grayscale, high-contrast, photocopy mode, bleed/safe-area checks.

## 11. Cloud + Native

- Use Supabase for accounts, source uploads, extraction runs, template versions, assets, exports, and shared links.
- Add local-first macOS storage later with sync to the same schema.
