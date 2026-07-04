import PrintUnionCore
import Foundation
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

struct ContentView: View {
  @State private var document = PrintUnionDefaults.sampleDocument
  @State private var selectedElementID: PrintElement.ID?
  @State private var importedSource: ImportedSource?
  @State private var isImporterPresented = false
  @State private var importError: String?

  var selectedElement: PrintElement? {
    document.elements.first { $0.id == selectedElementID }
      ?? document.setup.proposedElements.first { $0.id == selectedElementID }
  }

  var body: some View {
    HStack(spacing: 0) {
      WorktableView(
        document: document,
        importedSource: importedSource,
        importError: importError,
        selectedElementID: $selectedElementID,
        onImport: { isImporterPresented = true }
      )
      .frame(minWidth: 760, maxWidth: .infinity, maxHeight: .infinity)
      .padding(24)
      .background(Color(nsColor: .windowBackgroundColor))

      Divider()

      InspectorView(document: document, selectedElement: selectedElement)
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
  }

  private func handleImport(_ result: Result<[URL], Error>) {
    importError = nil

    do {
      guard let url = try result.get().first else { return }
      let source = try ImportedSource.load(from: url)
      importedSource = source
      document = document.applyingInitialStyleMapProposal(for: source)
      selectedElementID = document.elements.first(where: { $0.type == .text })?.id ?? document.elements.first?.id
    } catch {
      importError = error.localizedDescription
    }
  }
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
    let isImage = type?.conforms(to: .image) == true
    let isPDF = type?.conforms(to: .pdf) == true
    let image = isImage ? NSImage(data: data) : nil
    let pixelSize = image?.bestPixelSize

    return ImportedSource(
      fileName: url.lastPathComponent,
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

private extension PrintUnionDocument {
  func applyingInitialStyleMapProposal(for source: ImportedSource) -> PrintUnionDocument {
    var next = self
    next.intent = .eventAnnouncement
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

    let proposedElements = initialProposalElements(for: source)
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

  private func initialProposalElements(for source: ImportedSource) -> [PrintElement] {
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
        text: "EVENT TITLE",
        style: ["fontRole": "display", "case": "uppercase", "weight": "heavy"]
      ),
      PrintElement(
        id: "metadata-rows",
        type: .group,
        label: "Host, date, time, and venue rows",
        role: .whenWhere,
        frame: ElementFrame(x: 0.1, y: 0.38, width: 0.8, height: 0.14),
        style: ["typography": "small mono or ledger text", "layout": "ruled rows"]
      ),
      PrintElement(
        id: "label-chip-group",
        type: .chip,
        label: "Invitation chip / emphasis label",
        role: .mainInvitation,
        frame: ElementFrame(x: 0.12, y: 0.55, width: 0.34, height: 0.045),
        text: "TAG",
        style: ["treatment": "black ink reversal", "editableText": "true"]
      ),
      PrintElement(
        id: "body-copy-region",
        type: .text,
        label: "Body copy block",
        role: .details,
        frame: ElementFrame(x: 0.12, y: 0.62, width: 0.63, height: 0.2),
        text: "DETAILS",
        style: ["fontRole": "body", "measure": "narrow", "texture": "typewriter-like"]
      ),
      PrintElement(
        id: "footer-action-region",
        type: .group,
        label: "Footer action, QR, and mark",
        role: .callToAction,
        frame: ElementFrame(x: 0.09, y: 0.84, width: 0.8, height: 0.1),
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
  let document: PrintUnionDocument
  let importedSource: ImportedSource?
  let importError: String?
  @Binding var selectedElementID: PrintElement.ID?
  let onImport: () -> Void

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

      HStack(alignment: .top, spacing: 24) {
        VStack(alignment: .leading, spacing: 18) {
          SourcePreviewPanel(importedSource: importedSource, onImport: onImport)

          ElementListPanel(document: document, selectedElementID: $selectedElementID)
        }
        .frame(width: 330)

        PrintCanvasView(document: document, selectedElementID: $selectedElementID)
          .frame(minWidth: 420, maxWidth: .infinity, minHeight: 620, maxHeight: .infinity)
      }
      .frame(maxHeight: .infinity, alignment: .top)
    }
  }
}

private struct SourcePreviewPanel: View {
  let importedSource: ImportedSource?
  let onImport: () -> Void

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
      }
      .frame(height: 430)

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

private struct ElementListPanel: View {
  let document: PrintUnionDocument
  @Binding var selectedElementID: PrintElement.ID?

  private var visibleElements: [PrintElement] {
    document.setup.proposedElements.isEmpty ? document.elements : document.setup.proposedElements
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Elements", systemImage: "rectangle.3.group")
        .font(.headline)

      VStack(spacing: 6) {
        ForEach(visibleElements) { element in
          Button {
            selectedElementID = element.id
          } label: {
            HStack {
              Label(element.label, systemImage: iconName(for: element.type))
                .lineLimit(1)
              Spacer()
              Text(element.type.rawValue)
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
      }

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
  let document: PrintUnionDocument
  @Binding var selectedElementID: PrintElement.ID?

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("Editable Template")
          .font(.title2.bold())
        Spacer()
        Label("Print-ready preview", systemImage: "printer")
          .foregroundStyle(.secondary)
      }

      ZStack {
        Color(nsColor: .textBackgroundColor)

        GeometryReader { proxy in
          let page = fittedPageSize(in: proxy.size)
          ZStack {
            ZStack {
              pageBackground
              safeAreaOverlay
              renderedElements
            }
            .frame(width: page.width, height: page.height)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 12)
          }
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
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
          .onTapGesture {
            selectedElementID = element.id
          }
      }
    }
  }

  @ViewBuilder
  private func elementView(_ element: PrintElement) -> some View {
    switch element.type {
    case .background:
      Color.clear
    case .chip:
      Text(element.text ?? element.label)
        .font(.system(.headline, design: .monospaced).weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .background(.black)
    case .text:
      Text(element.text ?? element.label)
        .font(.system(size: 34, weight: .black, design: .default))
        .textCase(.uppercase)
        .minimumScaleFactor(0.35)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    default:
      RoundedRectangle(cornerRadius: 3)
        .stroke(.black.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        .overlay(Text(element.label).font(.caption).foregroundStyle(.secondary))
    }
  }

  @ViewBuilder
  private func selectionOverlay(for element: PrintElement) -> some View {
    if selectedElementID == element.id {
      Rectangle()
        .stroke(.blue, lineWidth: 2)
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
  let document: PrintUnionDocument
  let selectedElement: PrintElement?

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
        if let selectedElement {
          LabeledContent("Label", value: selectedElement.label)
          LabeledContent("Type", value: selectedElement.type.rawValue)
          LabeledContent("Editable", value: selectedElement.editable ? "Yes" : "No")
          LabeledContent("Reference", value: selectedElement.referenceOnly ? "Yes" : "No")
        } else {
          Text("Select an element on the page or in the sidebar.")
            .foregroundStyle(.secondary)
        }
      }
    }
    .formStyle(.grouped)
  }
}

#Preview("Print Union App") {
  ContentView()
    .frame(width: 1180, height: 760)
}
