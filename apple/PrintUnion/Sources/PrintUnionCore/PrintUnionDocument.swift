import Foundation

public enum PrintUnit: String, Codable, CaseIterable, Sendable {
  case inches = "in"
  case millimeters = "mm"
  case pixels = "px"
}

public struct PrintFormat: Codable, Equatable, Identifiable, Sendable {
  public var id: String
  public var label: String
  public var width: Double
  public var height: Double
  public var unit: PrintUnit

  public init(id: String, label: String, width: Double, height: Double, unit: PrintUnit) {
    self.id = id
    self.label = label
    self.width = width
    self.height = height
    self.unit = unit
  }
}

public enum PrintOrientation: String, Codable, CaseIterable, Identifiable, Sendable {
  case portrait
  case landscape

  public var id: String { rawValue }
}

public struct PrintMeasurement: Codable, Equatable, Sendable {
  public var value: Double
  public var unit: PrintUnit

  public init(value: Double, unit: PrintUnit) {
    self.value = value
    self.unit = unit
  }
}

public struct PrintCanvas: Codable, Equatable, Sendable {
  public var formatId: String
  public var width: Double
  public var height: Double
  public var unit: PrintUnit
  public var orientation: PrintOrientation

  public init(
    formatId: String,
    width: Double,
    height: Double,
    unit: PrintUnit,
    orientation: PrintOrientation = .portrait
  ) {
    self.formatId = formatId
    self.width = width
    self.height = height
    self.unit = unit
    self.orientation = orientation
  }
}

public struct PrintSettings: Codable, Equatable, Sendable {
  public var bleed: PrintMeasurement
  public var safeMargin: PrintMeasurement
  public var cropMarks: Bool
  public var grayscalePreview: Bool
  public var photocopyPreview: Bool
  public var outputMode: String

  public init(
    bleed: PrintMeasurement,
    safeMargin: PrintMeasurement,
    cropMarks: Bool = true,
    grayscalePreview: Bool = false,
    photocopyPreview: Bool = false,
    outputMode: String = "print-ready"
  ) {
    self.bleed = bleed
    self.safeMargin = safeMargin
    self.cropMarks = cropMarks
    self.grayscalePreview = grayscalePreview
    self.photocopyPreview = photocopyPreview
    self.outputMode = outputMode
  }
}

public enum InvitationIntent: String, Codable, CaseIterable, Identifiable, Sendable {
  case eventAnnouncement = "event-announcement"
  case openCall = "open-call"
  case workshopSheet = "workshop-sheet"
  case publicMeeting = "public-meeting"
  case mutualAidNotice = "mutual-aid-notice"
  case clubNightHandbill = "club-night-handbill"
  case readingGroup = "reading-group"

  public var id: String { rawValue }

  public var label: String {
    switch self {
    case .eventAnnouncement: "Event Announcement"
    case .openCall: "Open Call"
    case .workshopSheet: "Workshop Sheet"
    case .publicMeeting: "Public Meeting"
    case .mutualAidNotice: "Mutual Aid Notice"
    case .clubNightHandbill: "Club Night Handbill"
    case .readingGroup: "Reading Group Flyer"
    }
  }
}

public enum ContentRole: String, Codable, CaseIterable, Identifiable, Sendable {
  case category
  case hostPrefix
  case host
  case hostContext
  case title
  case whenWhere
  case mainInvitation
  case details
  case accessibilityNote
  case callToAction
  case contact

  public var id: String { rawValue }
}

public struct InvitationContent: Codable, Equatable, Sendable {
  public var category: String
  public var hostPrefix: String
  public var host: String
  public var hostContext: String
  public var title: String
  public var whenWhere: String
  public var mainInvitation: String
  public var details: String
  public var accessibilityNote: String
  public var callToAction: String
  public var contact: String

  public init(
    category: String = "",
    hostPrefix: String = "",
    host: String = "",
    hostContext: String = "",
    title: String = "",
    whenWhere: String = "",
    mainInvitation: String = "",
    details: String = "",
    accessibilityNote: String = "",
    callToAction: String = "",
    contact: String = ""
  ) {
    self.category = category
    self.hostPrefix = hostPrefix
    self.host = host
    self.hostContext = hostContext
    self.title = title
    self.whenWhere = whenWhere
    self.mainInvitation = mainInvitation
    self.details = details
    self.accessibilityNote = accessibilityNote
    self.callToAction = callToAction
    self.contact = contact
  }
}

public struct StyleFingerprint: Codable, Equatable, Sendable {
  public var family: String
  public var traits: [String]
  public var palette: [String]
  public var background: [String: String]
  public var typography: [String: String]
  public var grid: [String: String]
  public var texture: [String: String]

  public init(
    family: String = "",
    traits: [String] = [],
    palette: [String] = [],
    background: [String: String] = [:],
    typography: [String: String] = [:],
    grid: [String: String] = [:],
    texture: [String: String] = [:]
  ) {
    self.family = family
    self.traits = traits
    self.palette = palette
    self.background = background
    self.typography = typography
    self.grid = grid
    self.texture = texture
  }
}

public enum PrintElementType: String, Codable, CaseIterable, Identifiable, Sendable {
  case background
  case texture
  case border
  case divider
  case guide
  case text
  case chip
  case imagePlaceholder = "image-placeholder"
  case qrPlaceholder = "qr-placeholder"
  case logoMark = "logo-mark"
  case handwrittenMark = "handwritten-mark"
  case referenceImage = "reference-image"
  case group

  public var id: String { rawValue }
}

public struct ElementFrame: Codable, Equatable, Sendable {
  public var x: Double
  public var y: Double
  public var width: Double
  public var height: Double
  public var rotation: Double

  public init(x: Double, y: Double, width: Double, height: Double, rotation: Double = 0) {
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.rotation = rotation
  }
}

public struct PrintElement: Codable, Equatable, Identifiable, Sendable {
  public var id: String
  public var type: PrintElementType
  public var label: String
  public var role: ContentRole?
  public var frame: ElementFrame
  public var editable: Bool
  public var referenceOnly: Bool
  public var text: String?
  public var style: [String: String]
  public var children: [PrintElement]

  public init(
    id: String,
    type: PrintElementType,
    label: String,
    role: ContentRole? = nil,
    frame: ElementFrame,
    editable: Bool = true,
    referenceOnly: Bool = false,
    text: String? = nil,
    style: [String: String] = [:],
    children: [PrintElement] = []
  ) {
    self.id = id
    self.type = type
    self.label = label
    self.role = role
    self.frame = frame
    self.editable = editable
    self.referenceOnly = referenceOnly
    self.text = text
    self.style = style
    self.children = children
  }
}

public struct SetupAmbiguity: Codable, Equatable, Identifiable, Sendable {
  public var id: String
  public var question: String
  public var regionId: String?
  public var resolvedAs: String?

  public init(id: String, question: String, regionId: String? = nil, resolvedAs: String? = nil) {
    self.id = id
    self.question = question
    self.regionId = regionId
    self.resolvedAs = resolvedAs
  }
}

public struct StyleMapSetup: Codable, Equatable, Sendable {
  public var proposedElements: [PrintElement]
  public var ambiguities: [SetupAmbiguity]
  public var userConfirmedAt: Date?

  public init(
    proposedElements: [PrintElement] = [],
    ambiguities: [SetupAmbiguity] = [],
    userConfirmedAt: Date? = nil
  ) {
    self.proposedElements = proposedElements
    self.ambiguities = ambiguities
    self.userConfirmedAt = userConfirmedAt
  }
}

public struct ExportSettings: Codable, Equatable, Sendable {
  public var formats: [String]
  public var includeSourceReference: Bool
  public var multiUp: String?

  public init(formats: [String] = ["pdf", "png"], includeSourceReference: Bool = false, multiUp: String? = nil) {
    self.formats = formats
    self.includeSourceReference = includeSourceReference
    self.multiUp = multiUp
  }
}

public struct PrintUnionDocument: Codable, Equatable, Sendable {
  public var schemaVersion: String
  public var kind: String
  public var intent: InvitationIntent
  public var canvas: PrintCanvas
  public var printSettings: PrintSettings
  public var content: InvitationContent
  public var styleFingerprint: StyleFingerprint
  public var elements: [PrintElement]
  public var setup: StyleMapSetup
  public var exportSettings: ExportSettings

  public init(
    schemaVersion: String = "0.1.0",
    kind: String = "print-union-document",
    intent: InvitationIntent = .eventAnnouncement,
    canvas: PrintCanvas = PrintUnionDefaults.defaultCanvas,
    printSettings: PrintSettings = PrintUnionDefaults.defaultPrintSettings,
    content: InvitationContent = InvitationContent(),
    styleFingerprint: StyleFingerprint = StyleFingerprint(),
    elements: [PrintElement] = [],
    setup: StyleMapSetup = StyleMapSetup(),
    exportSettings: ExportSettings = ExportSettings()
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.intent = intent
    self.canvas = canvas
    self.printSettings = printSettings
    self.content = content
    self.styleFingerprint = styleFingerprint
    self.elements = elements
    self.setup = setup
    self.exportSettings = exportSettings
  }
}

public enum PrintUnionDefaults {
  public static let formats: [PrintFormat] = [
    PrintFormat(id: "letter", label: "Letter", width: 8.5, height: 11, unit: .inches),
    PrintFormat(id: "tabloid", label: "Tabloid", width: 11, height: 17, unit: .inches),
    PrintFormat(id: "a4", label: "A4", width: 210, height: 297, unit: .millimeters),
    PrintFormat(id: "handbill-half-letter", label: "Half-letter handbill", width: 5.5, height: 8.5, unit: .inches),
    PrintFormat(id: "social-poster", label: "4:5 poster", width: 1080, height: 1350, unit: .pixels)
  ]

  public static let defaultCanvas = PrintCanvas(formatId: "letter", width: 8.5, height: 11, unit: .inches)

  public static let defaultPrintSettings = PrintSettings(
    bleed: PrintMeasurement(value: 0.125, unit: .inches),
    safeMargin: PrintMeasurement(value: 0.25, unit: .inches)
  )

  public static let sampleDocument = PrintUnionDocument(
    content: InvitationContent(
      category: "public-invitation",
      hostPrefix: "Hosted by",
      host: "Print Union",
      hostContext: "A digital print shop for community-facing announcements.",
      title: "Critique Night",
      whenWhere: "Thursday / 6:30 PM / Community Studio",
      mainInvitation: "All levels welcome",
      details: "Bring a work in progress, a question, or a useful eye.",
      accessibilityNote: "Come solo, quiet, late, or curious.",
      callToAction: "RSVP",
      contact: "printunion.local"
    ),
    styleFingerprint: StyleFingerprint(
      family: "gallery-ledger",
      traits: ["ruled-grid", "monospace", "paper-texture", "black-and-white"],
      palette: ["#111111", "#f7f7f4"]
    ),
    elements: [
      PrintElement(
        id: "page-background",
        type: .background,
        label: "Page background",
        frame: ElementFrame(x: 0, y: 0, width: 1, height: 1),
        style: ["color": "#f7f7f4", "texture": "paper"]
      ),
      PrintElement(
        id: "headline",
        type: .text,
        label: "Hero title",
        role: .title,
        frame: ElementFrame(x: 0.12, y: 0.16, width: 0.76, height: 0.2),
        text: "EVENT TITLE",
        style: ["fontRole": "headline", "weight": "900"]
      ),
      PrintElement(
        id: "cta-chip",
        type: .chip,
        label: "Call to action chip",
        role: .callToAction,
        frame: ElementFrame(x: 0.12, y: 0.82, width: 0.22, height: 0.04),
        text: "RSVP"
      )
    ]
  )
}
