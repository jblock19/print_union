# Product Architecture

Print Union should treat the template JSON as the product contract. The web app, a future macOS app, and any extraction service can all read and write the same format.

## System Shape

```text
Upload
  -> Style Map intent and print setup
  -> Image normalization
  -> Python/OpenCV geometry extraction
  -> AI style interpretation
  -> Style fingerprint
  -> User-confirmed element schema
  -> Editable template JSON
  -> Renderer/editor
  -> Print export or save
```

## First Product Milestone

Start with one style family: a black-and-white gallery ledger flyer with paper texture, dotted dividers, strict rows, inverse label chips, QR/footer blocks, and large headline typography.

The first importer should understand content roles enough to protect the public invitation: title, date/time, place, host, access note, and call to action. It should not require perfect OCR to succeed. Text can remain placeholder-based while the style and structure are reconstructed.

## Product Ethos

Print Union is a print-first tool for group, community, and event invitations. It should make flyers that still feel like they belong on a wall, table, pole, counter, or photocopier glass.

## Platform Strategy

- Web: Next.js renderer/editor and hosted sharing.
- macOS: native file intake, local processing, offline drafts, and export.
- Shared: portable template schema, extraction engine outputs, and asset metadata.

## Cloud Strategy

Use Supabase later for user accounts, source uploads, extraction runs, template versions, assets, exports, and sharing. Keep local browser/macOS storage for drafts and private experiments.
