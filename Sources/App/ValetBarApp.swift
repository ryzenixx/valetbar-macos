import SwiftUI
import AppKit

@main
struct ValetBarApp: App {
    @StateObject private var viewModel = ValetViewModel()
    @StateObject private var updaterController = UpdaterController()
    
    private var menuBarIcon: NSImage {
        // Try Bundle.module (Dev/Xcode - DEBUG ONLY)
        #if DEBUG
        if let moduleUrl = Bundle.module.url(forResource: "Assets/MenuBarIcon", withExtension: "png"),
           let image = NSImage(contentsOf: moduleUrl) {
            image.isTemplate = true
            image.size = CGSize(width: 15, height: 15)
            return image
        }
        #endif
        
        // Try Bundle.main (Production/Manual Build)
        if let resourcePath = Bundle.main.resourcePath {
            let iconPath = resourcePath + "/MenuBarIcon.png"
            if let image = NSImage(contentsOfFile: iconPath) {
                image.isTemplate = true
                image.size = CGSize(width: 15, height: 15)
                return image
            }
        }
        
        // print("WARNING: Could not load MenuBarIcon.png from bundle")
        return NSImage(systemSymbolName: "server.rack", accessibilityDescription: nil) ?? NSImage()
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel, updaterController: updaterController)
                .frame(minWidth: 380, maxWidth: 380, minHeight: 500, maxHeight: 500)
        } label: {
            Image(nsImage: menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
