export const printFormats = {
  letter: {
    id: "letter",
    label: "Letter",
    width: 8.5,
    height: 11,
    unit: "in"
  },
  tabloid: {
    id: "tabloid",
    label: "Tabloid",
    width: 11,
    height: 17,
    unit: "in"
  },
  a4: {
    id: "a4",
    label: "A4",
    width: 210,
    height: 297,
    unit: "mm"
  },
  handbillHalfLetter: {
    id: "handbill-half-letter",
    label: "Half-letter handbill",
    width: 5.5,
    height: 8.5,
    unit: "in"
  },
  socialPoster: {
    id: "social-poster",
    label: "4:5 poster",
    width: 1080,
    height: 1350,
    unit: "px"
  }
};

export const invitationIntents = [
  {
    id: "event-announcement",
    label: "Event Announcement",
    priorityRoles: ["title", "whenWhere", "location", "callToAction"]
  },
  {
    id: "open-call",
    label: "Open Call",
    priorityRoles: ["title", "deadline", "callToAction", "details"]
  },
  {
    id: "workshop-sheet",
    label: "Workshop Sheet",
    priorityRoles: ["title", "whenWhere", "host", "accessibilityNote"]
  },
  {
    id: "public-meeting",
    label: "Public Meeting",
    priorityRoles: ["title", "whenWhere", "location", "host"]
  },
  {
    id: "mutual-aid-notice",
    label: "Mutual Aid Notice",
    priorityRoles: ["title", "callToAction", "location", "contact"]
  },
  {
    id: "club-night-handbill",
    label: "Club Night Handbill",
    priorityRoles: ["title", "whenWhere", "location", "price"]
  },
  {
    id: "reading-group",
    label: "Reading Group Flyer",
    priorityRoles: ["title", "whenWhere", "details", "accessibilityNote"]
  }
];

export const contentRoles = [
  {
    id: "category",
    label: "Category",
    description: "The broad invitation type or community context."
  },
  {
    id: "hostPrefix",
    label: "Host Prefix",
    description: "Small phrase that introduces the maker, host, or collective."
  },
  {
    id: "host",
    label: "Host / Collective",
    description: "The person, group, venue, or collective issuing the invitation."
  },
  {
    id: "hostContext",
    label: "Host Context",
    description: "A short identity line that explains the host or community."
  },
  {
    id: "title",
    label: "Title",
    description: "The primary public-facing headline."
  },
  {
    id: "whenWhere",
    label: "When / Where",
    description: "The core time and place line."
  },
  {
    id: "mainInvitation",
    label: "Invitation Line",
    description: "A short hook, access cue, or promise."
  },
  {
    id: "details",
    label: "Details",
    description: "The main explanatory body copy."
  },
  {
    id: "accessibilityNote",
    label: "Access / First-Timer Note",
    description: "A welcoming note, access detail, cost note, or participation cue."
  },
  {
    id: "callToAction",
    label: "Call to Action",
    description: "How someone replies, RSVPs, signs up, donates, or shows up."
  },
  {
    id: "contact",
    label: "Contact",
    description: "Contact info, URL, handle, or QR-linked destination."
  }
];

export const elementTypes = [
  "background",
  "texture",
  "border",
  "divider",
  "guide",
  "text",
  "chip",
  "image-placeholder",
  "qr-placeholder",
  "logo-mark",
  "handwritten-mark",
  "reference-image",
  "group"
];

export const archetypeFamilies = [
  {
    id: "gallery-ledger",
    label: "Gallery Ledger",
    traits: ["ruled-grid", "monospace", "institutional", "paper-texture", "black-and-white"]
  },
  {
    id: "pasteup-zine",
    label: "Pasteup Zine",
    traits: ["collage", "photocopy", "cut-paper", "asymmetric", "high-contrast"]
  },
  {
    id: "community-notice",
    label: "Community Notice",
    traits: ["legible", "bulletin-board", "sturdy-hierarchy", "public-service", "photocopy-friendly"]
  }
];

export const defaultPrintSettings = {
  formatId: "letter",
  orientation: "portrait",
  bleed: {
    value: 0.125,
    unit: "in"
  },
  safeMargin: {
    value: 0.25,
    unit: "in"
  },
  cropMarks: true,
  grayscalePreview: false,
  photocopyPreview: false,
  outputMode: "print-ready"
};

export function createEmptyPrintUnionDocument(overrides = {}) {
  return {
    schemaVersion: "0.1.0",
    kind: "print-union-document",
    intent: "event-announcement",
    canvas: {
      formatId: "letter",
      width: printFormats.letter.width,
      height: printFormats.letter.height,
      unit: printFormats.letter.unit,
      orientation: "portrait"
    },
    printSettings: defaultPrintSettings,
    content: {
      category: "",
      hostPrefix: "",
      host: "",
      hostContext: "",
      title: "",
      whenWhere: "",
      mainInvitation: "",
      details: "",
      accessibilityNote: "",
      callToAction: "",
      contact: ""
    },
    styleFingerprint: {
      family: "",
      traits: [],
      palette: [],
      background: {},
      typography: {},
      grid: {},
      texture: {}
    },
    elements: [],
    setup: {
      proposedElements: [],
      ambiguities: [],
      userConfirmedAt: null
    },
    exportSettings: {
      formats: ["pdf", "png"],
      includeSourceReference: false,
      multiUp: null
    },
    ...overrides
  };
}

export function legacyFlyerToPrintUnionDocument(flyer) {
  return createEmptyPrintUnionDocument({
    intent: "event-announcement",
    content: {
      category: flyer.category || "",
      hostPrefix: flyer.signaturePrefix || "",
      host: flyer.communityName || "",
      hostContext: flyer.communityLine || "",
      title: flyer.title || "",
      whenWhere: flyer.whenWhereLine || "",
      mainInvitation: flyer.mainInvitation || "",
      details: flyer.whatWeDo || "",
      accessibilityNote: flyer.firstTimerNote || "",
      callToAction: "",
      contact: ""
    },
    styleFingerprint: {
      family: flyer.vibe || "",
      traits: [],
      palette: [flyer.accentOne, flyer.accentTwo, flyer.accentThree].filter(Boolean),
      background: {
        color: flyer.backgroundColor || ""
      },
      typography: {
        textColor: flyer.textColor || ""
      },
      grid: {},
      texture: {},
      depth: flyer.depth || "soft"
    }
  });
}
