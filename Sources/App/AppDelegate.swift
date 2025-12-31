import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var appState: ValetAppState!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        appState = ValetAppState()
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 500)
        popover.behavior = .transient
        
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(viewModel: appState.viewModel, updaterController: appState.updaterController)
                .frame(width: 380, height: 500)
        )
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = getMenuBarIcon()
            button.action = #selector(buttonPressed(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func buttonPressed(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit Valet Bar", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                if let button = statusItem.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func getMenuBarIcon() -> NSImage {
        #if DEBUG
        if let moduleUrl = Bundle.module.url(forResource: "Assets/MenuBarIcon", withExtension: "png"),
           let image = NSImage(contentsOf: moduleUrl) {
            image.isTemplate = true
            image.size = CGSize(width: 15, height: 15)
            return image
        }
        #endif
        
        if let resourcePath = Bundle.main.resourcePath {
            let iconPath = resourcePath + "/MenuBarIcon.png"
            if let image = NSImage(contentsOfFile: iconPath) {
                image.isTemplate = true
                image.size = CGSize(width: 15, height: 15)
                return image
            }
        }
        
        return NSImage(systemSymbolName: "server.rack", accessibilityDescription: nil) ?? NSImage()
    }
}
