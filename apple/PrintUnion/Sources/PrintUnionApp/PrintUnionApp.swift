import SwiftUI

#if os(macOS)
import AppKit
#endif

@main
struct PrintUnionApp: App {
  init() {
    #if os(macOS)
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate(ignoringOtherApps: true)
    #endif
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 1080, minHeight: 720)
    }
  }
}
