import Foundation
import Sparkle
import SwiftUI

class UpdaterController: NSObject, ObservableObject, SPUUpdaterDelegate {
    private var updaterController: SPUStandardUpdaterController?
    
    @Published var canCheckForUpdates = false
    
    override init() {
        super.init()
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
    }
    
    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }
    
    func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        // Appcast loaded
    }
    
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        // Update found
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        // No update found
    }
    
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        // Error handling
    }
}
