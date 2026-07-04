import PrintUnionCore
import SwiftUI

struct ContentView: View {
  @State private var document = PrintUnionDefaults.sampleDocument
  @State private var selectedElementID: PrintElement.ID?

  var selectedElement: PrintElement? {
    document.elements.first { $0.id == selectedElementID }
  }

  var body: some View {
    NavigationSplitView {
      SidebarView(document: document, selectedElementID: $selectedElementID)
    } content: {
      PrintCanvasView(document: document, selectedElementID: $selectedElementID)
        .padding(28)
        .background(Color(nsColor: .windowBackgroundColor))
    } detail: {
      InspectorView(document: document, selectedElement: selectedElement)
    }
    .navigationTitle("Print Union")
  }
}

private struct SidebarView: View {
  let document: PrintUnionDocument
  @Binding var selectedElementID: PrintElement.ID?

  var body: some View {
    List(selection: $selectedElementID) {
      Section("Intent") {
        LabeledContent("Kind", value: document.intent.label)
        LabeledContent("Size", value: "\(document.canvas.formatId.uppercased()) / \(document.canvas.orientation.rawValue)")
      }

      Section("Content Roles") {
        roleRow("Title", document.content.title)
        roleRow("When / Where", document.content.whenWhere)
        roleRow("Host", document.content.host)
        roleRow("Invitation", document.content.mainInvitation)
        roleRow("CTA", document.content.callToAction)
      }

      Section("Elements") {
        ForEach(document.elements) { element in
          Label(element.label, systemImage: iconName(for: element.type))
            .tag(element.id)
        }
      }
    }
    .listStyle(.sidebar)
  }

  private func roleRow(_ label: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value.isEmpty ? "Not set" : value)
        .lineLimit(2)
    }
    .padding(.vertical, 2)
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
        Text("Style Map")
          .font(.title2.bold())
        Spacer()
        Label("Print-ready preview", systemImage: "printer")
          .foregroundStyle(.secondary)
      }

      GeometryReader { proxy in
        let page = fittedPageSize(in: proxy.size)

        ZStack {
          Color(nsColor: .textBackgroundColor)

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
    .padding()
  }
}
