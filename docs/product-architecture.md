# Product Architecture

Flyer Style Studio should treat the template JSON as the product contract. The web app, a future macOS app, and any extraction service can all read and write the same format.

## System Shape

```text
Upload
  -> Image normalization
  -> Style extraction
  -> Style fingerprint
  -> Editable template JSON
  -> Renderer/editor
  -> Export or save
```

## First Product Milestone

Start with one style family: a black-and-white gallery ledger flyer with paper texture, dotted dividers, strict rows, inverse label chips, QR/footer blocks, and large headline typography.

The first importer does not need to understand the exact text. It should detect visual structure and produce editable placeholders.

## Platform Strategy

- Web: Next.js renderer/editor and hosted sharing.
- macOS: native file intake, local processing, offline drafts, and export.
- Shared: portable template schema, extraction engine outputs, and asset metadata.

## Cloud Strategy

Use Supabase later for user accounts, source uploads, extraction runs, template versions, assets, exports, and sharing. Keep local browser/macOS storage for drafts and private experiments.
