# Template Schema Draft

The Print Union document is the shared contract between the setup page, editor, extraction services, Supabase, and future macOS app. It combines print constraints, semantic invitation content, style extraction, and editable elements.

The first code version lives in `lib/printUnionSchema.js`.

## Document Shape

```json
{
  "schemaVersion": "0.1.0",
  "kind": "print-union-document",
  "intent": "event-announcement",
  "canvas": {
    "formatId": "letter",
    "width": 8.5,
    "height": 11,
    "unit": "in",
    "orientation": "portrait"
  },
  "printSettings": {
    "bleed": { "value": 0.125, "unit": "in" },
    "safeMargin": { "value": 0.25, "unit": "in" },
    "cropMarks": true,
    "grayscalePreview": false,
    "photocopyPreview": false
  },
  "content": {},
  "styleFingerprint": {},
  "elements": [],
  "setup": {},
  "exportSettings": {}
}
```

## Content Roles

The existing flyer tool already has the core public-invitation model. Print Union keeps that spine and makes it portable:

```json
{
  "category": "activity-partners",
  "hostPrefix": "Hosted by",
  "host": "Bolm Arts",
  "hostContext": "A monthly critique night for working artists.",
  "title": "Critique Night",
  "whenWhere": "07.09.2026 / 5:30-8:00PM / Hive Mind Studios",
  "mainInvitation": "All levels welcome",
  "details": "Bring complete or in-progress work for feedback.",
  "accessibilityNote": "First-timers welcome.",
  "callToAction": "RSVP",
  "contact": "bolmarts.org/events"
}
```

These roles are not meant to turn Print Union into event-management software. They exist so the print hierarchy knows what must survive: title, time, place, host, access note, and call to action.

## Style Fingerprint

```json
{
  "canvas": {
    "width": 1080,
    "height": 1350,
    "aspectRatio": "4:5",
    "padding": 48
  },
  "background": {
    "color": "#f7f7f4",
    "texture": "paper-fiber",
    "noise": 0.18
  },
  "palette": ["#111111", "#f7f7f4"],
  "grid": {
    "outerBorder": true,
    "borderRadius": 8,
    "verticalGuides": [0.1, 0.9],
    "horizontalDividers": [0.1, 0.14, 0.39, 0.44, 0.49, 0.54, 0.84, 0.89],
    "lineStyle": "dotted-hairline"
  },
  "typography": {
    "headline": "extra-bold-condensed-sans",
    "body": "monospace",
    "meta": "monospace-letterspaced"
  },
  "traits": [
    "black-and-white",
    "strict-grid",
    "gallery-notice",
    "inverse-label-chips",
    "paper-texture"
  ]
}
```

## Editable Elements

Every visible piece that should survive reconstruction becomes an editable element or a locked reference element.

```json
{
  "elements": [
    {
      "id": "page-background",
      "type": "background",
      "editable": true
    },
    {
      "id": "outer-border",
      "type": "border",
      "editable": true
    },
    {
      "id": "headline",
      "type": "text",
      "role": "headline",
      "text": "EVENT TITLE",
      "x": 0.13,
      "y": 0.17,
      "width": 0.75,
      "height": 0.22,
      "fontRole": "headline"
    },
    {
      "id": "tag-chip-1",
      "type": "chip",
      "text": "TAG",
      "x": 0.13,
      "y": 0.56
    },
    {
      "id": "qr-placeholder",
      "type": "image-placeholder",
      "role": "qr",
      "x": 0.13,
      "y": 0.9,
      "width": 0.08,
      "height": 0.08
    }
  ]
}
```

## Setup State

The Style Map page should preserve the proposal and the user's decisions:

```json
{
  "setup": {
    "proposedElements": [],
    "ambiguities": [
      {
        "id": "ambiguous-bottom-mark",
        "question": "Should this mark become a logo image or editable text?",
        "regionId": "bottom-center",
        "resolvedAs": null
      }
    ],
    "userConfirmedAt": null
  }
}
```
