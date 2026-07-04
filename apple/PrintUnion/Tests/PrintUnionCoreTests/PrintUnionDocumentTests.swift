import Testing
import Foundation
@testable import PrintUnionCore

@Test func printUnionDocumentRoundTripsThroughJSON() throws {
  let document = PrintUnionDefaults.sampleDocument
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys]

  let data = try encoder.encode(document)
  let decoded = try JSONDecoder().decode(PrintUnionDocument.self, from: data)

  #expect(decoded == document)
  #expect(decoded.content.title == "Critique Night")
  #expect(decoded.elements.contains { $0.type == .chip })
}

@Test func defaultDocumentIsPrintFirst() {
  let document = PrintUnionDocument()

  #expect(document.kind == "print-union-document")
  #expect(document.canvas.formatId == "letter")
  #expect(document.printSettings.cropMarks)
  #expect(document.exportSettings.formats.contains("pdf"))
}
