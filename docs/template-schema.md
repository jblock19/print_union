# Template Schema Draft

The importer should output two related objects: a style fingerprint and editable elements.

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
