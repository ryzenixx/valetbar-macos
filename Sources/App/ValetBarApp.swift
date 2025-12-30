import SwiftUI
import AppKit

@main
struct ValetBarApp: App {
    @StateObject private var viewModel = ValetViewModel()
    
    private var menuBarIcon: NSImage {
        if let path = Bundle.module.path(forResource: "MenuBarIcon", ofType: "png"),
           let image = NSImage(contentsOfFile: path) {
            image.isTemplate = true
            image.size = CGSize(width: 15, height: 15)
            return image
        }
        
        print("WARNING: Could not load MenuBarIcon.png from bundle")
        return NSImage(systemSymbolName: "server.rack", accessibilityDescription: nil) ?? NSImage()
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
                .frame(minWidth: 380, maxWidth: 380, minHeight: 500, maxHeight: 500)
        } label: {
            Image(nsImage: menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
