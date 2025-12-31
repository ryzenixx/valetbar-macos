import Foundation
import Sparkle
import SwiftUI

/// A wrapper around Sparkle's SPUStandardUpdaterController to bridge it with SwiftUI.
class UpdaterController: NSObject, ObservableObject, SPUUpdaterDelegate {
    private var updaterController: SPUStandardUpdaterController?
    
    @Published var canCheckForUpdates = false
    
    override init() {
        super.init()
        // We initialize the updater only if we are in a packaged app usually, 
        // but Sparkle handles dev builds gracefully if configured.
        // We use the standard user driver (Standard Sparkle UI window)
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
    }
    
    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }
    
    // MARK: - SPUUpdaterDelegate
    
    func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        // Did find valid update feed
        print("[Sparkle] Appcast loaded: \(appcast.items.count) items")
    }
    
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        // Update available
        print("[Sparkle] Update found: \(item.displayVersionString)")
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        print("[Sparkle] No update found")
    }
    
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        print("[Sparkle] Error: \(error.localizedDescription)")
    }
}
