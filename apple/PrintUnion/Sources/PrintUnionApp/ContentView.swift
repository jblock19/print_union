import PrintUnionCore
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
      importedSource = try ImportedSource.load(from: url)
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

    return ImportedSource(
      fileName: url.lastPathComponent,
      typeLabel: isPDF ? "PDF source" : isImage ? "Image source" : "Source file",
      byteCount: data.count,
      imageData: isImage ? data : nil
    )
  }

  var byteCountLabel: String {
    ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
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
          Text("\(importedSource.typeLabel) / \(importedSource.byteCountLabel)")
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

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Elements", systemImage: "rectangle.3.group")
        .font(.headline)

      VStack(spacing: 6) {
        ForEach(document.elements) { element in
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
