import PrintUnionCore
import Foundation
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

struct ContentView: View {
  @State private var document = PrintUnionDefaults.blankDocument
  @State private var selectedElementID: PrintElement.ID?
  @State private var importedSource: ImportedSource?
  @State private var isImporterPresented = false
  @State private var importError: String?
  @State private var didLoadTestSource = false

  var selectedElement: PrintElement? {
    document.elements.first { $0.id == selectedElementID }
      ?? document.setup.proposedElements.first { $0.id == selectedElementID }
  }

  private var currentGuideStep: GuideStep {
    if importedSource == nil {
      return .uploadSource
    }

    if document.setup.userConfirmedAt == nil {
      return .replaceContent
    }

    if selectedElementID == nil {
      return .editOnCanvas
    }

    return .reviewAndPrint
  }

  var body: some View {
    HStack(spacing: 0) {
      WorktableView(
        document: $document,
        importedSource: importedSource,
        importError: importError,
        guideStep: currentGuideStep,
        selectedElementID: $selectedElementID,
        onImport: { isImporterPresented = true },
        onReset: resetWorktable,
        onGuideAction: handleGuideAction,
        onDropSources: handleDrop
      )
      .frame(minWidth: 760, maxWidth: .infinity, maxHeight: .infinity)
      .padding(24)
      .background(Color(nsColor: .windowBackgroundColor))

      Divider()

      InspectorView(document: $document, selectedElementID: $selectedElementID)
        .frame(width: 340)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    .frame(minWidth: 1120, minHeight: 760)
    .fileImporter(
      isPresented: $isImporterPresented,
      allowedContentTypes: [.image, .pdf],
      allowsMultipleSelection: false,
      onCompletion: handleImport
    )
    .onAppear(perform: loadTestSourceIfNeeded)
  }

  private func handleImport(_ result: Result<[URL], Error>) {
    importError = nil

    do {
      guard let url = try result.get().first else { return }
      try importSource(from: url)
    } catch {
      importError = error.localizedDescription
    }
  }

  private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
    importError = nil

    if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
      provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
        let droppedURL = droppedURL(from: item)

        DispatchQueue.main.async {
          if let error {
            importError = error.localizedDescription
            return
          }

          guard let url = droppedURL else {
            importError = "Could not read the dropped file."
            return
          }

          do {
            try importSource(from: url)
          } catch {
            importError = error.localizedDescription
          }
        }
      }
      return true
    }

    if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) {
      let fileName = suggestedFileName(from: provider, fallback: "Dropped screenshot", fileExtension: "png")

      provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
        DispatchQueue.main.async {
          if let error {
            importError = error.localizedDescription
            return
          }

          guard let data else {
            importError = "Could not read the dropped image."
            return
          }

          processImportedSource(ImportedSource.load(data: data, fileName: fileName, type: .image))
        }
      }
      return true
    }

    if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) }) {
      let fileName = suggestedFileName(from: provider, fallback: "Dropped source", fileExtension: "pdf")

      provider.loadDataRepresentation(forTypeIdentifier: UTType.pdf.identifier) { data, error in
        DispatchQueue.main.async {
          if let error {
            importError = error.localizedDescription
            return
          }

          guard let data else {
            importError = "Could not read the dropped PDF."
            return
          }

          processImportedSource(ImportedSource.load(data: data, fileName: fileName, type: .pdf))
        }
      }
      return true
    }

    importError = "Drop an image, screenshot, or PDF source."
    return false
  }

  private func importSource(from url: URL) throws {
    let source = try ImportedSource.load(from: url)
    processImportedSource(source)
  }

  private func processImportedSource(_ source: ImportedSource) {
    importedSource = source
    document = document.applyingInitialStyleMapProposal(for: source)
    selectedElementID = nil
  }

  private func resetWorktable() {
    document = PrintUnionDefaults.blankDocument
    selectedElementID = nil
    importedSource = nil
    importError = nil
  }

  private func loadTestSourceIfNeeded() {
    guard !didLoadTestSource else { return }
    didLoadTestSource = true

    guard let path = ProcessInfo.processInfo.environment["PRINT_UNION_TEST_SOURCE"], !path.isEmpty else {
      return
    }

    do {
      try importSource(from: URL(fileURLWithPath: path))
    } catch {
      importError = error.localizedDescription
    }
  }

  private func handleGuideAction(_ step: GuideStep) {
    switch step {
    case .uploadSource:
      isImporterPresented = true
    case .replaceContent:
      selectedElementID = document.firstElementID(for: .title)
    case .editOnCanvas:
      selectedElementID = document.firstElementID(for: .title)
    case .reviewAndPrint:
      selectedElementID = document.firstElementID(for: .callToAction) ?? document.elements.first?.id
    }
  }
}

private func droppedURL(from droppedItem: NSSecureCoding?) -> URL? {
  if let url = droppedItem as? URL {
    return url
  }

  if let data = droppedItem as? Data {
    return URL(dataRepresentation: data, relativeTo: nil)
  }

  if let string = droppedItem as? String {
    return URL(string: string)
  }

  return nil
}

private func suggestedFileName(from provider: NSItemProvider, fallback: String, fileExtension: String) -> String {
  let name = provider.suggestedName ?? fallback
  if URL(fileURLWithPath: name).pathExtension.isEmpty {
    return "\(name).\(fileExtension)"
  }

  return name
}

struct ImportedSource: Equatable, Sendable {
  var fileName: String
  var typeLabel: String
  var byteCount: Int
  var imageData: Data?
  var pixelWidth: Int?
  var pixelHeight: Int?

  static func load(from url: URL) throws -> ImportedSource {
    let didStartAccessing = url.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing {
        url.stopAccessingSecurityScopedResource()
      }
    }

    let data = try Data(contentsOf: url)
    let type = UTType(filenameExtension: url.pathExtension)

    return load(data: data, fileName: url.lastPathComponent, type: type)
  }

  static func load(data: Data, fileName: String, type: UTType?) -> ImportedSource {
    let isImage = type?.conforms(to: .image) == true
    let isPDF = type?.conforms(to: .pdf) == true
    let image = isImage ? NSImage(data: data) : nil
    let pixelSize = image?.bestPixelSize

    return ImportedSource(
      fileName: fileName,
      typeLabel: isPDF ? "PDF source" : isImage ? "Image source" : "Source file",
      byteCount: data.count,
      imageData: isImage ? data : nil,
      pixelWidth: pixelSize?.width,
      pixelHeight: pixelSize?.height
    )
  }

  var byteCountLabel: String {
    ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
  }

  var dimensionLabel: String {
    guard let pixelWidth, let pixelHeight else {
      return "size pending"
    }

    return "\(pixelWidth) x \(pixelHeight) px"
  }
}

enum GuideStep: Int, CaseIterable, Identifiable {
  case uploadSource = 1
  case replaceContent
  case editOnCanvas
  case reviewAndPrint

  var id: Int { rawValue }

  var title: String {
    switch self {
    case .uploadSource: "Start with a source flyer"
    case .replaceContent: "Replace the message"
    case .editOnCanvas: "Edit directly on the flyer"
    case .reviewAndPrint: "Review the print version"
    }
  }

  var message: String {
    switch self {
    case .uploadSource:
      "Drop a screenshot, poster, or PDF onto the canvas. Print Union will use it as the design source."
    case .replaceContent:
      "Use the Content Slots panel to write your title, host, date, details, and RSVP while keeping the source’s visual structure."
    case .editOnCanvas:
      "Click into text on the flyer preview to revise it in place. Select a slot to fine-tune its role or bounds in the inspector."
    case .reviewAndPrint:
      "Check the page margins, design parts, and final wording. Print export comes next; for now this is the final review step."
    }
  }

  var actionTitle: String {
    switch self {
    case .uploadSource: "Choose File"
    case .replaceContent: "Jump to Title"
    case .editOnCanvas: "Select Title"
    case .reviewAndPrint: "Check Footer"
    }
  }

  var iconName: String {
    switch self {
    case .uploadSource: "doc.badge.plus"
    case .replaceContent: "text.cursor"
    case .editOnCanvas: "pencil.and.outline"
    case .reviewAndPrint: "printer"
    }
  }
}

private extension PrintUnionDocument {
  func element(withID id: PrintElement.ID?) -> PrintElement? {
    guard let id else { return nil }

    return elements.first { $0.id == id }
      ?? setup.proposedElements.first { $0.id == id }
  }

  mutating func updateElement(withID id: PrintElement.ID, _ update: (inout PrintElement) -> Void) {
    if let elementIndex = elements.firstIndex(where: { $0.id == id }) {
      update(&elements[elementIndex])
    }

    if let proposedIndex = setup.proposedElements.firstIndex(where: { $0.id == id }) {
      update(&setup.proposedElements[proposedIndex])
    }
  }

  mutating func removeElement(withID id: PrintElement.ID) {
    elements.removeAll { $0.id == id }
    setup.proposedElements.removeAll { $0.id == id }
    setup.ambiguities.removeAll { $0.regionId == id }
  }

  mutating func confirmElement(withID id: PrintElement.ID) {
    guard let proposedElement = setup.proposedElements.first(where: { $0.id == id }) else {
      return
    }

    if proposedElement.type != .referenceImage && !elements.contains(where: { $0.id == id }) {
      elements.append(proposedElement)
    }

    setup.ambiguities.removeAll { $0.regionId == id }
  }

  mutating func updateTextElements(for role: ContentRole, text: String) {
    for index in elements.indices where elements[index].role == role {
      elements[index].text = text
    }

    for index in setup.proposedElements.indices where setup.proposedElements[index].role == role {
      setup.proposedElements[index].text = text
    }
  }

  func firstElementID(for role: ContentRole) -> PrintElement.ID? {
    elements.first { $0.role == role }?.id
      ?? setup.proposedElements.first { $0.role == role }?.id
  }

  func applyingInitialStyleMapProposal(for source: ImportedSource) -> PrintUnionDocument {
    var next = self
    next.intent = .eventAnnouncement
    next.content = InvitationContent(
      category: "public-invitation",
      hostPrefix: "Presented by",
      host: "Your group",
      hostContext: "",
      title: "YOUR EVENT TITLE",
      whenWhere: "Date / time / venue",
      mainInvitation: "ALL WELCOME",
      details: "Describe the gathering, who it is for, and what people should bring or expect.",
      accessibilityNote: "",
      callToAction: "RSVP",
      contact: "your-site.org/events"
    )
    next.canvas = inferredCanvas(for: source)
    next.styleFingerprint = StyleFingerprint(
      family: "source-derived",
      traits: [
        "needs-review",
        "print-source",
        source.imageData == nil ? "pdf-or-unknown-size" : "image-source",
        "style-map-proposal"
      ],
      palette: ["#111111", "#f7f7f4"],
      background: [
        "proposal": "paper field, texture, and ink density should be sampled from source",
        "sourceFile": source.fileName
      ],
      typography: [
        "proposal": "identify headline, metadata, body, chip, and footer roles before exact font matching",
        "confidence": "low"
      ],
      grid: [
        "proposal": "detect outer bounds, safe margin, rows, columns, dividers, and alignment anchors",
        "confidence": "medium"
      ],
      texture: [
        "proposal": "preserve paper grain and photocopy/noise character as reusable background layers",
        "confidence": "medium"
      ]
    )

    let proposedElements = initialProposalElements(for: source, content: next.content)
    next.setup = StyleMapSetup(
      proposedElements: proposedElements,
      ambiguities: [
        SetupAmbiguity(
          id: "source-purpose",
          question: "What kind of public invitation is this source: event, open call, workshop, meeting, mutual aid notice, or something else?",
          regionId: nil
        ),
        SetupAmbiguity(
          id: "editable-vs-atmosphere",
          question: "Which source marks are content that should stay editable, and which are atmosphere or print texture?",
          regionId: "source-reference"
        ),
        SetupAmbiguity(
          id: "footer-mark",
          question: "Should footer marks like logos, QR codes, stamps, or signatures become reusable fields or fixed reference art?",
          regionId: "footer-action-region"
        )
      ]
    )
    next.elements = proposedElements.filter { $0.type != .referenceImage }

    return next
  }

  private func inferredCanvas(for source: ImportedSource) -> PrintCanvas {
    guard let width = source.pixelWidth, let height = source.pixelHeight, height > 0 else {
      return PrintUnionDefaults.defaultCanvas
    }

    let ratio = Double(width) / Double(height)
    if ratio > 1.15 {
      return PrintCanvas(formatId: "letter", width: 11, height: 8.5, unit: .inches, orientation: .landscape)
    }

    return PrintUnionDefaults.defaultCanvas
  }

  private func initialProposalElements(for source: ImportedSource, content: InvitationContent) -> [PrintElement] {
    [
      PrintElement(
        id: "source-reference",
        type: .referenceImage,
        label: "Source reference",
        frame: ElementFrame(x: 0, y: 0, width: 1, height: 1),
        editable: false,
        referenceOnly: true,
        style: [
          "fileName": source.fileName,
          "dimensions": source.dimensionLabel,
          "purpose": "kept as visual evidence during setup"
        ]
      ),
      PrintElement(
        id: "page-background",
        type: .background,
        label: "Page background / paper",
        frame: ElementFrame(x: 0, y: 0, width: 1, height: 1),
        style: [
          "color": "#f7f7f4",
          "texture": "sample from source"
        ]
      ),
      PrintElement(
        id: "page-bounds",
        type: .border,
        label: "Outer border / print bounds",
        frame: ElementFrame(x: 0.045, y: 0.045, width: 0.91, height: 0.91),
        editable: true,
        style: ["stroke": "thin black rule", "confidence": "medium"]
      ),
      PrintElement(
        id: "divider-system",
        type: .group,
        label: "Rules, dividers, and grid",
        frame: ElementFrame(x: 0.045, y: 0.09, width: 0.91, height: 0.82),
        style: ["contains": "horizontal rows, vertical gutters, alignment guides"]
      ),
      PrintElement(
        id: "headline-region",
        type: .text,
        label: "Primary headline region",
        role: .title,
        frame: ElementFrame(x: 0.12, y: 0.17, width: 0.74, height: 0.2),
        text: content.title,
        style: ["fontRole": "display", "case": "uppercase", "weight": "heavy"]
      ),
      PrintElement(
        id: "metadata-rows",
        type: .text,
        label: "Host, date, time, and venue rows",
        role: .whenWhere,
        frame: ElementFrame(x: 0.1, y: 0.38, width: 0.8, height: 0.14),
        text: "\(content.host) / \(content.whenWhere)",
        style: ["typography": "small mono or ledger text", "layout": "ruled rows"]
      ),
      PrintElement(
        id: "label-chip-group",
        type: .chip,
        label: "Invitation chip / emphasis label",
        role: .mainInvitation,
        frame: ElementFrame(x: 0.12, y: 0.55, width: 0.34, height: 0.045),
        text: content.mainInvitation,
        style: ["treatment": "black ink reversal", "editableText": "true"]
      ),
      PrintElement(
        id: "body-copy-region",
        type: .text,
        label: "Body copy block",
        role: .details,
        frame: ElementFrame(x: 0.12, y: 0.62, width: 0.63, height: 0.2),
        text: content.details,
        style: ["fontRole": "body", "measure": "narrow", "texture": "typewriter-like"]
      ),
      PrintElement(
        id: "footer-action-region",
        type: .text,
        label: "Footer action, QR, and mark",
        role: .callToAction,
        frame: ElementFrame(x: 0.09, y: 0.84, width: 0.8, height: 0.1),
        text: "\(content.callToAction) @ \(content.contact)",
        style: ["contains": "call to action, QR placeholder, logo or signature mark"]
      )
    ]
  }
}

private extension NSImage {
  var bestPixelSize: (width: Int, height: Int)? {
    guard let representation = representations.max(by: {
      ($0.pixelsWide * $0.pixelsHigh) < ($1.pixelsWide * $1.pixelsHigh)
    }) else {
      return nil
    }

    guard representation.pixelsWide > 0, representation.pixelsHigh > 0 else {
      return nil
    }

    return (representation.pixelsWide, representation.pixelsHigh)
  }
}

private struct WorktableView: View {
  @Binding var document: PrintUnionDocument
  let importedSource: ImportedSource?
  let importError: String?
  let guideStep: GuideStep
  @Binding var selectedElementID: PrintElement.ID?
  let onImport: () -> Void
  let onReset: () -> Void
  let onGuideAction: (GuideStep) -> Void
  let onDropSources: ([NSItemProvider]) -> Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Style Map Worktable")
            .font(.title2.bold())
          Text("Bring in a printed source, then rebuild it as editable public-invitation elements.")
            .foregroundStyle(.secondary)
        }

        Spacer()

        Button {
          onReset()
        } label: {
          Label("Reset", systemImage: "arrow.counterclockwise")
        }
        .buttonStyle(.bordered)

        Button {
          onImport()
        } label: {
          Label(importedSource == nil ? "Import Source" : "Replace Source", systemImage: "doc.badge.plus")
        }
        .buttonStyle(.borderedProminent)
      }

      if let importError {
        Label(importError, systemImage: "exclamationmark.triangle")
          .foregroundStyle(.orange)
      }

      GuideCoachCard(step: guideStep, onAction: onGuideAction)

      HStack(alignment: .top, spacing: 24) {
        ScrollView {
          VStack(alignment: .leading, spacing: 18) {
            SourcePreviewPanel(importedSource: importedSource, onImport: onImport, onDropSources: onDropSources)

            if importedSource != nil {
              RepurposeContentPanel(document: $document, selectedElementID: $selectedElementID)

              ElementListPanel(document: document, selectedElementID: $selectedElementID)
            }
          }
          .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(width: 330)
        .scrollIndicators(.visible)

        PrintCanvasView(
          document: $document,
          hasSource: importedSource != nil,
          selectedElementID: $selectedElementID,
          onImport: onImport,
          onDropSources: onDropSources
        )
          .frame(minWidth: 420, maxWidth: .infinity, minHeight: 620, maxHeight: .infinity)
      }
      .frame(maxHeight: .infinity, alignment: .top)
    }
  }
}

private struct SourcePreviewPanel: View {
  let importedSource: ImportedSource?
  let onImport: () -> Void
  let onDropSources: ([NSItemProvider]) -> Bool
  @State private var isDropTargeted = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label("Source", systemImage: "viewfinder")
          .font(.headline)
        Spacer()
      }

      ZStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color(nsColor: .textBackgroundColor))
          .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .stroke(.black.opacity(0.18), lineWidth: 1)
          )

        if let importedSource {
          importedPreview(importedSource)
        } else {
          emptyPreview
        }

        if isDropTargeted {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.accentColor.opacity(0.12))
            .overlay(
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            )
            .overlay(
              Label("Drop source", systemImage: "arrow.down.doc")
                .font(.headline)
                .padding(10)
                .background(.regularMaterial, in: Capsule())
            )
        }
      }
      .frame(height: 430)
      .onDrop(
        of: [UTType.fileURL.identifier, UTType.image.identifier, UTType.pdf.identifier],
        isTargeted: $isDropTargeted,
        perform: onDropSources
      )

      if let importedSource {
        VStack(alignment: .leading, spacing: 4) {
          Text(importedSource.fileName)
            .font(.callout.weight(.semibold))
            .lineLimit(2)
          Text("\(importedSource.typeLabel) / \(importedSource.dimensionLabel) / \(importedSource.byteCountLabel)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  @ViewBuilder
  private func importedPreview(_ source: ImportedSource) -> some View {
    if let imageData = source.imageData, let image = platformImage(from: imageData) {
      Image(nsImage: image)
        .resizable()
        .scaledToFit()
        .padding(12)
    } else {
      VStack(spacing: 12) {
        Image(systemName: "doc.richtext")
          .font(.system(size: 42))
          .foregroundStyle(.secondary)
        Text("PDF source imported")
          .font(.headline)
        Text("PDF page preview comes next; the source file is ready for the Style Map flow.")
          .font(.caption)
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
          .padding(.horizontal)
      }
    }
  }

  private var emptyPreview: some View {
    VStack(spacing: 12) {
      Image(systemName: "plus.viewfinder")
        .font(.system(size: 42))
        .foregroundStyle(.secondary)
      Text("Import a flyer, poster, or notice")
        .font(.headline)
      Text("PNG, JPEG, WebP, and PDF sources will become the reference for the Style Map.")
        .font(.caption)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
      Button("Choose File", action: onImport)
    }
  }

  private func platformImage(from data: Data) -> NSImage? {
    NSImage(data: data)
  }
}

private struct GuideCoachCard: View {
  let step: GuideStep
  let onAction: (GuideStep) -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: step.iconName)
        .font(.title3)
        .foregroundStyle(Color.accentColor)
        .frame(width: 28)

      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 8) {
          Text("Step \(step.rawValue) of \(GuideStep.allCases.count)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)
          Text(step.title)
            .font(.headline)
        }

        Text(step.message)
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 12)

      actionButton
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(Color.accentColor.opacity(0.22), lineWidth: 1)
    )
  }

  @ViewBuilder
  private var actionButton: some View {
    if step == .uploadSource {
      Button {
        onAction(step)
      } label: {
        Label(step.actionTitle, systemImage: "arrow.right")
      }
      .buttonStyle(.borderedProminent)
    } else {
      Button {
        onAction(step)
      } label: {
        Label(step.actionTitle, systemImage: "arrow.right")
      }
      .buttonStyle(.bordered)
    }
  }
}

private struct RepurposeContentPanel: View {
  @Binding var document: PrintUnionDocument
  @Binding var selectedElementID: PrintElement.ID?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Repurpose This Flyer", systemImage: "square.and.pencil")
        .font(.headline)

      VStack(alignment: .leading, spacing: 8) {
        StepPill(number: "1", title: "Keep the design", detail: "Paper, grid, dividers, spacing, and print feel.")
        StepPill(number: "2", title: "Replace the message", detail: "Write your event into the detected content slots.")
        StepPill(number: "3", title: "Print it", detail: "Export once the layout feels like yours.")
      }

      VStack(alignment: .leading, spacing: 10) {
        Text("Content Slots")
          .font(.subheadline.weight(.semibold))

        slotField("Title", role: .title, text: titleBinding)
        slotField("Host", role: .whenWhere, text: hostBinding)
        slotField("Date / Time / Venue", role: .whenWhere, text: whenWhereBinding)
        slotField("Invitation Line", role: .mainInvitation, text: mainInvitationBinding)
        slotField("Details", role: .details, text: detailsBinding, isMultiline: true)
        slotField("RSVP / Action", role: .callToAction, text: callToActionBinding)
        slotField("Contact", role: .callToAction, text: contactBinding)
      }

      Button {
        confirmContentSlots()
      } label: {
        Label("Use These Content Slots", systemImage: "checkmark.circle")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(Color.black.opacity(0.08), lineWidth: 1)
    )
  }

  private var titleBinding: Binding<String> {
    contentBinding(\.title, role: .title)
  }

  private var hostBinding: Binding<String> {
    Binding(
      get: { document.content.host },
      set: { value in
        document.content.host = value
        syncWhenWhereText()
      }
    )
  }

  private var whenWhereBinding: Binding<String> {
    Binding(
      get: { document.content.whenWhere },
      set: { value in
        document.content.whenWhere = value
        syncWhenWhereText()
      }
    )
  }

  private var mainInvitationBinding: Binding<String> {
    contentBinding(\.mainInvitation, role: .mainInvitation)
  }

  private var detailsBinding: Binding<String> {
    contentBinding(\.details, role: .details)
  }

  private var callToActionBinding: Binding<String> {
    Binding(
      get: { document.content.callToAction },
      set: { value in
        document.content.callToAction = value
        syncFooterText()
      }
    )
  }

  private var contactBinding: Binding<String> {
    Binding(
      get: { document.content.contact },
      set: { value in
        document.content.contact = value
        syncFooterText()
      }
    )
  }

  private func slotField(
    _ label: String,
    role: ContentRole,
    text: Binding<String>,
    isMultiline: Bool = false
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(label)
          .font(.caption.weight(.semibold))
        Spacer()
        Button {
          selectedElementID = document.firstElementID(for: role)
        } label: {
          Image(systemName: "scope")
        }
        .buttonStyle(.borderless)
        .help("Select this slot on the page")
      }

      if isMultiline {
        EditableTextView(
          text: text,
          font: .monospacedSystemFont(ofSize: 13, weight: .regular)
        )
          .frame(minHeight: 82)
      } else {
        EditableTextField(
          text: text,
          placeholder: label
        )
        .frame(height: 26)
      }
    }
  }

  private func contentBinding(_ keyPath: WritableKeyPath<InvitationContent, String>, role: ContentRole) -> Binding<String> {
    Binding(
      get: { document.content[keyPath: keyPath] },
      set: { value in
        document.content[keyPath: keyPath] = value
        document.updateTextElements(for: role, text: value)
      }
    )
  }

  private func syncWhenWhereText() {
    document.updateTextElements(for: .whenWhere, text: "\(document.content.host) / \(document.content.whenWhere)")
  }

  private func syncFooterText() {
    document.updateTextElements(for: .callToAction, text: "\(document.content.callToAction) @ \(document.content.contact)")
  }

  private func confirmContentSlots() {
    let roles: [ContentRole] = [.title, .whenWhere, .mainInvitation, .details, .callToAction]
    roles.forEach { role in
      if let id = document.firstElementID(for: role) {
        document.confirmElement(withID: id)
      }
    }
    document.setup.userConfirmedAt = Date()
    selectedElementID = document.firstElementID(for: .title)
  }
}

private struct StepPill: View {
  let number: String
  let title: String
  let detail: String

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Text(number)
        .font(.caption.bold())
        .frame(width: 18, height: 18)
        .background(Circle().fill(Color.accentColor.opacity(0.16)))
        .foregroundStyle(Color.accentColor)

      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(.caption.weight(.semibold))
        Text(detail)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

private struct ElementListPanel: View {
  let document: PrintUnionDocument
  @Binding var selectedElementID: PrintElement.ID?

  private var visibleElements: [PrintElement] {
    document.setup.proposedElements.isEmpty ? document.elements : document.setup.proposedElements
  }

  private var designParts: [PrintElement] {
    visibleElements.filter { element in
      element.role == nil || [.background, .texture, .border, .divider, .guide, .referenceImage, .group].contains(element.type)
    }
  }

  private var contentSlots: [PrintElement] {
    visibleElements.filter { $0.role != nil && !designParts.contains($0) }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Style Map", systemImage: "rectangle.3.group")
        .font(.headline)

      elementSection("Design Parts", elements: designParts)
      elementSection("Content Slots", elements: contentSlots)

      if !document.setup.ambiguities.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Label("Needs Review", systemImage: "questionmark.bubble")
            .font(.headline)
            .padding(.top, 8)

          ForEach(document.setup.ambiguities) { ambiguity in
            Text(ambiguity.question)
              .font(.caption)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
              .padding(10)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                  .fill(Color(nsColor: .textBackgroundColor))
              )
              .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                  .stroke(Color.black.opacity(0.08), lineWidth: 1)
              )
          }
        }
      }
    }
  }

  private func elementSection(_ title: String, elements: [PrintElement]) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)

      ForEach(elements) { element in
        elementRow(element)
      }
    }
  }

  private func elementRow(_ element: PrintElement) -> some View {
    Button {
      selectedElementID = element.id
    } label: {
      HStack {
        Label(element.label, systemImage: iconName(for: element.type))
          .lineLimit(1)
        Spacer()
        Text(element.role?.displayName ?? element.type.displayName)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 7, style: .continuous)
          .fill(selectedElementID == element.id ? Color.accentColor.opacity(0.14) : Color(nsColor: .textBackgroundColor))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 7, style: .continuous)
          .stroke(selectedElementID == element.id ? Color.accentColor.opacity(0.55) : Color.black.opacity(0.08), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }

  private func iconName(for type: PrintElementType) -> String {
    switch type {
    case .background, .texture: "square.fill"
    case .border, .divider, .guide: "line.3.horizontal"
    case .text: "textformat"
    case .chip: "tag"
    case .imagePlaceholder, .referenceImage: "photo"
    case .qrPlaceholder: "qrcode"
    case .logoMark, .handwrittenMark: "signature"
    case .group: "rectangle.3.group"
    }
  }
}

private struct PrintCanvasView: View {
  @Binding var document: PrintUnionDocument
  let hasSource: Bool
  @Binding var selectedElementID: PrintElement.ID?
  let onImport: () -> Void
  let onDropSources: ([NSItemProvider]) -> Bool
  @State private var isDropTargeted = false

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text(hasSource ? "Repurpose This Flyer" : "Blank Print Canvas")
          .font(.title2.bold())
        Spacer()
        Label("Print-ready preview", systemImage: "printer")
          .foregroundStyle(.secondary)
      }

      ZStack {
        Color(nsColor: .textBackgroundColor)

        GeometryReader { proxy in
          let page = fittedPageSize(in: proxy.size)
          ScrollView([.horizontal, .vertical]) {
            ZStack {
              ZStack {
                pageBackground
                safeAreaOverlay
                renderedElements
                if !hasSource {
                  blankCanvasPrompt
                }
              }
              .frame(width: page.width, height: page.height)
              .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
              .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                  .stroke(.black.opacity(0.55), lineWidth: 1)
              )
              .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 12)
            }
            .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
            .padding(20)
          }
          .scrollIndicators(.visible)
          .onDrop(
            of: [UTType.fileURL.identifier, UTType.image.identifier, UTType.pdf.identifier],
            isTargeted: $isDropTargeted,
            perform: onDropSources
          )
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
  }

  private var blankCanvasPrompt: some View {
    VStack(spacing: 14) {
      Image(systemName: isDropTargeted ? "arrow.down.doc.fill" : "doc.badge.plus")
        .font(.system(size: 38))
        .foregroundStyle(Color.accentColor)

      VStack(spacing: 4) {
        Text(isDropTargeted ? "Drop to start" : "Drop a flyer screenshot, poster, or PDF here")
          .font(.headline)
        Text("Use an existing flyer’s design language as a reusable print template.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      Button("Choose File", action: onImport)
        .buttonStyle(.borderedProminent)
    }
    .padding(24)
    .frame(maxWidth: 340)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(Color.black.opacity(0.08), lineWidth: 1)
    )
  }

  private var pageBackground: some View {
    Rectangle()
      .fill(Color(red: 0.97, green: 0.97, blue: 0.94))
      .overlay(
        Canvas { context, size in
          for index in stride(from: 0, to: Int(size.height), by: 12) {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: Double(index)))
            path.addLine(to: CGPoint(x: size.width, y: Double(index)))
            context.stroke(path, with: .color(.black.opacity(0.025)), lineWidth: 0.5)
          }
        }
      )
  }

  private var safeAreaOverlay: some View {
    Rectangle()
      .stroke(.black.opacity(0.16), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
      .padding(28)
  }

  private var renderedElements: some View {
    GeometryReader { proxy in
      ForEach(document.elements) { element in
        elementView(element)
          .frame(
            width: element.frame.width * proxy.size.width,
            height: element.frame.height * proxy.size.height
          )
          .position(
            x: (element.frame.x + element.frame.width / 2) * proxy.size.width,
            y: (element.frame.y + element.frame.height / 2) * proxy.size.height
          )
          .overlay(selectionOverlay(for: element))
      }
    }
  }

  @ViewBuilder
  private func elementView(_ element: PrintElement) -> some View {
    switch element.type {
    case .background:
      Color.clear
    case .chip:
      EditableTextField(
        text: textBinding(for: element.id),
        font: .monospacedSystemFont(ofSize: 14, weight: .bold),
        textColor: .white,
        backgroundColor: .black,
        isBordered: false,
        drawsBackground: true
      )
      .padding(.horizontal, 8)
      .background(.black)
    case .text:
      textElementView(element)
    default:
      RoundedRectangle(cornerRadius: 3)
        .stroke(.black.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        .overlay {
          if selectedElementID == element.id {
            Text(element.label)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
    }
  }

  private func textElementView(_ element: PrintElement) -> some View {
    return Group {
      switch element.role {
      case .title:
        EditableTextField(
          text: textBinding(for: element.id),
          font: .systemFont(ofSize: 34, weight: .black),
          isBordered: false,
          drawsBackground: false
        )
      case .whenWhere:
        EditableTextView(
          text: textBinding(for: element.id),
          font: .monospacedSystemFont(ofSize: 11, weight: .semibold),
          isBordered: false,
          drawsBackground: false
        )
      case .details:
        EditableTextView(
          text: textBinding(for: element.id),
          font: .monospacedSystemFont(ofSize: 13, weight: .medium),
          isBordered: false,
          drawsBackground: false
        )
      case .callToAction:
        EditableTextField(
          text: textBinding(for: element.id),
          font: .monospacedSystemFont(ofSize: 14, weight: .bold),
          isBordered: false,
          drawsBackground: false
        )
      default:
        EditableTextField(
          text: textBinding(for: element.id),
          font: .monospacedSystemFont(ofSize: 13, weight: .semibold),
          isBordered: false,
          drawsBackground: false
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private func textBinding(for id: PrintElement.ID) -> Binding<String> {
    Binding(
      get: { document.element(withID: id)?.text ?? "" },
      set: { value in
        let role = document.element(withID: id)?.role
        document.updateElement(withID: id) { element in
          element.text = value
        }
        syncContent(for: role, text: value)
      }
    )
  }

  private func syncContent(for role: ContentRole?, text: String) {
    guard let role else { return }

    switch role {
    case .title:
      document.content.title = text
    case .mainInvitation:
      document.content.mainInvitation = text
    case .details:
      document.content.details = text
    case .callToAction:
      document.content.callToAction = text
    case .whenWhere:
      document.content.whenWhere = text
    default:
      break
    }
  }

  @ViewBuilder
  private func selectionOverlay(for element: PrintElement) -> some View {
    if selectedElementID == element.id {
      Rectangle()
        .stroke(.blue, lineWidth: 2)
        .allowsHitTesting(false)
    }
  }

  private func fittedPageSize(in available: CGSize) -> CGSize {
    let ratio = document.canvas.width / document.canvas.height
    let maxWidth = max(available.width - 40, 120)
    let maxHeight = max(available.height - 40, 120)
    var width = maxWidth
    var height = width / ratio

    if height > maxHeight {
      height = maxHeight
      width = height * ratio
    }

    return CGSize(width: width, height: height)
  }
}

private struct InspectorView: View {
  @Binding var document: PrintUnionDocument
  @Binding var selectedElementID: PrintElement.ID?

  private var selectedElement: PrintElement? {
    document.element(withID: selectedElementID)
  }

  var body: some View {
    Form {
      Section("Print") {
        LabeledContent("Format", value: document.canvas.formatId)
        LabeledContent("Bleed", value: "\(document.printSettings.bleed.value) \(document.printSettings.bleed.unit.rawValue)")
        LabeledContent("Safe margin", value: "\(document.printSettings.safeMargin.value) \(document.printSettings.safeMargin.unit.rawValue)")
        LabeledContent("Crop marks", value: document.printSettings.cropMarks ? "On" : "Off")
      }

      Section("Style") {
        LabeledContent("Family", value: document.styleFingerprint.family)
        LabeledContent("Traits", value: document.styleFingerprint.traits.joined(separator: ", "))
      }

      Section("Selected") {
        if let selectedElement, let selectedElementID {
          EditableTextField(text: labelBinding(for: selectedElementID), placeholder: "Name")
            .frame(height: 26)

          Picker("Type", selection: typeBinding(for: selectedElementID)) {
            ForEach(PrintElementType.allCases) { type in
              Text(type.displayName).tag(type)
            }
          }

          Picker("Role", selection: roleBinding(for: selectedElementID)) {
            Text("None").tag("")
            ForEach(ContentRole.allCases) { role in
              Text(role.displayName).tag(role.rawValue)
            }
          }

          Toggle("Editable", isOn: editableBinding(for: selectedElementID))
          Toggle("Reference only", isOn: referenceOnlyBinding(for: selectedElementID))

          if selectedElement.type == .text || selectedElement.type == .chip || selectedElement.text != nil {
            EditableTextView(text: textBinding(for: selectedElementID), font: .systemFont(ofSize: 13))
              .frame(minHeight: 72)
          }

          LabeledContent("ID", value: selectedElement.id)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        } else {
          Text("Select an element on the page or in the sidebar.")
            .foregroundStyle(.secondary)
        }
      }

      if let selectedElementID, selectedElement != nil {
        Section("Bounds") {
          frameSlider("X", value: frameBinding(for: selectedElementID, keyPath: \.x))
          frameSlider("Y", value: frameBinding(for: selectedElementID, keyPath: \.y))
          frameSlider("Width", value: frameBinding(for: selectedElementID, keyPath: \.width))
          frameSlider("Height", value: frameBinding(for: selectedElementID, keyPath: \.height))
        }

        Section("Proposal") {
          Button {
            document.confirmElement(withID: selectedElementID)
          } label: {
            Label("Confirm Element", systemImage: "checkmark.circle")
          }

          Button(role: .destructive) {
            document.removeElement(withID: selectedElementID)
            self.selectedElementID = document.elements.first?.id ?? document.setup.proposedElements.first?.id
          } label: {
            Label("Remove Element", systemImage: "trash")
          }
        }
      }
    }
    .formStyle(.grouped)
  }

  private func labelBinding(for id: PrintElement.ID) -> Binding<String> {
    Binding(
      get: { document.element(withID: id)?.label ?? "" },
      set: { newValue in
        document.updateElement(withID: id) { element in
          element.label = newValue
        }
      }
    )
  }

  private func typeBinding(for id: PrintElement.ID) -> Binding<PrintElementType> {
    Binding(
      get: { document.element(withID: id)?.type ?? .group },
      set: { newValue in
        document.updateElement(withID: id) { element in
          element.type = newValue
        }
      }
    )
  }

  private func roleBinding(for id: PrintElement.ID) -> Binding<String> {
    Binding(
      get: { document.element(withID: id)?.role?.rawValue ?? "" },
      set: { newValue in
        document.updateElement(withID: id) { element in
          element.role = newValue.isEmpty ? nil : ContentRole(rawValue: newValue)
        }
      }
    )
  }

  private func editableBinding(for id: PrintElement.ID) -> Binding<Bool> {
    Binding(
      get: { document.element(withID: id)?.editable ?? false },
      set: { newValue in
        document.updateElement(withID: id) { element in
          element.editable = newValue
        }
      }
    )
  }

  private func referenceOnlyBinding(for id: PrintElement.ID) -> Binding<Bool> {
    Binding(
      get: { document.element(withID: id)?.referenceOnly ?? false },
      set: { newValue in
        document.updateElement(withID: id) { element in
          element.referenceOnly = newValue
        }
      }
    )
  }

  private func textBinding(for id: PrintElement.ID) -> Binding<String> {
    Binding(
      get: { document.element(withID: id)?.text ?? "" },
      set: { newValue in
        document.updateElement(withID: id) { element in
          element.text = newValue.isEmpty ? nil : newValue
        }
      }
    )
  }

  private func frameBinding(for id: PrintElement.ID, keyPath: WritableKeyPath<ElementFrame, Double>) -> Binding<Double> {
    Binding(
      get: { document.element(withID: id)?.frame[keyPath: keyPath] ?? 0 },
      set: { newValue in
        document.updateElement(withID: id) { element in
          element.frame[keyPath: keyPath] = min(max(newValue, 0), 1)
        }
      }
    )
  }

  private func frameSlider(_ label: String, value: Binding<Double>) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(label)
        Spacer()
        Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
          .foregroundStyle(.secondary)
          .monospacedDigit()
      }
      Slider(value: value, in: 0...1)
    }
  }
}

private extension PrintElementType {
  var displayName: String {
    switch self {
    case .background: "Background"
    case .texture: "Texture"
    case .border: "Border"
    case .divider: "Divider"
    case .guide: "Guide"
    case .text: "Text"
    case .chip: "Chip"
    case .imagePlaceholder: "Image placeholder"
    case .qrPlaceholder: "QR placeholder"
    case .logoMark: "Logo mark"
    case .handwrittenMark: "Handwritten mark"
    case .referenceImage: "Reference image"
    case .group: "Group"
    }
  }
}

private extension ContentRole {
  var displayName: String {
    switch self {
    case .category: "Category"
    case .hostPrefix: "Host prefix"
    case .host: "Host"
    case .hostContext: "Host context"
    case .title: "Title"
    case .whenWhere: "When / where"
    case .mainInvitation: "Main invitation"
    case .details: "Details"
    case .accessibilityNote: "Accessibility note"
    case .callToAction: "Call to action"
    case .contact: "Contact"
    }
  }
}

#if os(macOS)
private struct EditableTextField: NSViewRepresentable {
  @Binding var text: String
  var placeholder: String = ""
  var font: NSFont = .systemFont(ofSize: NSFont.systemFontSize)
  var textColor: NSColor = .labelColor
  var backgroundColor: NSColor = .textBackgroundColor
  var isBordered: Bool = true
  var drawsBackground: Bool = true
  var onFocus: () -> Void = {}

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text, onFocus: onFocus)
  }

  func makeNSView(context: Context) -> NSTextField {
    let textField = NSTextField(string: text)
    textField.placeholderString = placeholder
    textField.delegate = context.coordinator
    textField.font = font
    textField.textColor = textColor
    textField.backgroundColor = backgroundColor
    textField.isBordered = isBordered
    textField.drawsBackground = drawsBackground
    textField.isEditable = true
    textField.isSelectable = true
    textField.focusRingType = isBordered ? .default : .none
    textField.lineBreakMode = .byClipping
    textField.cell?.isScrollable = true
    return textField
  }

  func updateNSView(_ textField: NSTextField, context: Context) {
    context.coordinator.text = $text
    context.coordinator.onFocus = onFocus
    textField.placeholderString = placeholder
    textField.font = font
    textField.textColor = textColor
    textField.backgroundColor = backgroundColor
    textField.isBordered = isBordered
    textField.drawsBackground = drawsBackground
    textField.focusRingType = isBordered ? .default : .none

    if textField.stringValue != text {
      textField.stringValue = text
    }
  }

  final class Coordinator: NSObject, NSTextFieldDelegate {
    var text: Binding<String>
    var onFocus: () -> Void

    init(text: Binding<String>, onFocus: @escaping () -> Void) {
      self.text = text
      self.onFocus = onFocus
    }

    func controlTextDidBeginEditing(_ notification: Notification) {
      onFocus()
    }

    func controlTextDidChange(_ notification: Notification) {
      guard let textField = notification.object as? NSTextField else { return }
      text.wrappedValue = textField.stringValue
    }
  }
}

private struct EditableTextView: NSViewRepresentable {
  @Binding var text: String
  var font: NSFont = .systemFont(ofSize: NSFont.systemFontSize)
  var textColor: NSColor = .labelColor
  var backgroundColor: NSColor = .textBackgroundColor
  var isBordered: Bool = true
  var drawsBackground: Bool = true
  var onFocus: () -> Void = {}

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text, onFocus: onFocus)
  }

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.borderType = isBordered ? .bezelBorder : .noBorder
    scrollView.drawsBackground = drawsBackground
    scrollView.backgroundColor = backgroundColor

    let textView = NSTextView()
    textView.string = text
    textView.delegate = context.coordinator
    textView.font = font
    textView.textColor = textColor
    textView.backgroundColor = backgroundColor
    textView.drawsBackground = drawsBackground
    textView.isEditable = true
    textView.isSelectable = true
    textView.isRichText = false
    textView.allowsUndo = true
    textView.textContainerInset = NSSize(width: 4, height: 4)
    textView.textContainer?.widthTracksTextView = true
    textView.autoresizingMask = [.width]

    scrollView.documentView = textView
    context.coordinator.textView = textView
    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    context.coordinator.text = $text
    context.coordinator.onFocus = onFocus
    scrollView.borderType = isBordered ? .bezelBorder : .noBorder
    scrollView.drawsBackground = drawsBackground
    scrollView.backgroundColor = backgroundColor

    guard let textView = scrollView.documentView as? NSTextView else { return }
    textView.font = font
    textView.textColor = textColor
    textView.backgroundColor = backgroundColor
    textView.drawsBackground = drawsBackground

    if textView.string != text {
      textView.string = text
    }
  }

  final class Coordinator: NSObject, NSTextViewDelegate {
    var text: Binding<String>
    var onFocus: () -> Void
    weak var textView: NSTextView?

    init(text: Binding<String>, onFocus: @escaping () -> Void) {
      self.text = text
      self.onFocus = onFocus
    }

    func textDidBeginEditing(_ notification: Notification) {
      onFocus()
    }

    func textDidChange(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else { return }
      text.wrappedValue = textView.string
    }
  }
}
#endif

#Preview("Print Union App") {
  ContentView()
    .frame(width: 1180, height: 760)
}
