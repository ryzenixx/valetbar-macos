import Foundation
import AppKit

struct GitHubRelease: Codable {
    let tagName: String
    let htmlUrl: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
    }
}

@MainActor
class UpdateService: ObservableObject {
    @Published var isUpdateAvailable: Bool = false
    @Published var latestVersion: String?
    @Published var releaseUrl: URL?
    
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    
    func checkForUpdates() async {
        guard let url = URL(string: "https://api.github.com/repos/ryzenixx/valetbar-macos/releases/latest") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            
            let remoteVersion = release.tagName.replacingOccurrences(of: "v", with: "")
            let currentVersion = AppConfig.appVersion
            
            if isVersion(remoteVersion, greaterThan: currentVersion) {
                self.latestVersion = remoteVersion
                self.releaseUrl = URL(string: release.htmlUrl)
                self.isUpdateAvailable = true
            }
        } catch {
            print("Failed to check for updates: \(error)")
        }
    }
    
    func downloadAndInstall() async {
        guard let url = releaseUrl else { return }
        
        isDownloading = true
        
        do {
            // 1. Download DMG
            let (localURL, _) = try await URLSession.shared.download(from: url)
            
            // 2. Move to specific temp location
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent("ValetBar_Update")
            try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            let targetURL = tempDir.appendingPathComponent("ValetBar-Update.dmg")
            
            if fileManager.fileExists(atPath: targetURL.path) {
                try fileManager.removeItem(at: targetURL)
            }
            try fileManager.moveItem(at: localURL, to: targetURL)
            
            // 3. Mount DMG
            print("Mounting DMG at \(targetURL.path)...")
            let mountProcess = Process()
            mountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            mountProcess.arguments = ["attach", targetURL.path]
            try mountProcess.run()
            mountProcess.waitUntilExit()
            
            // 4. Open the mounted volume
            // The volume name is usually "ValetBar Installer" (set in release.yml)
            // But we can try to open the generic volume path if we knew the mount point.
            // Since hdiutil attaches to /Volumes/ValetBar Installer by default:
            let volumePath = "/Volumes/ValetBar Installer"
            
            // Wait slightly for mount
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: volumePath)
            
            // 5. Quit App to allow overwrite
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NSApplication.shared.terminate(nil)
            }
            
        } catch {
            print("Update failed: \(error)")
            isDownloading = false
        }
    }
    
    private func isVersion(_ versionA: String, greaterThan versionB: String) -> Bool {
        let componentsA = versionA.split(separator: ".").compactMap { Int($0) }
        let componentsB = versionB.split(separator: ".").compactMap { Int($0) }
        
        for (a, b) in zip(componentsA, componentsB) {
            if a > b { return true }
            if a < b { return false }
        }
        
        // If one is longer (e.g. 1.0.1 vs 1.0), it's newer
        return componentsA.count > componentsB.count
    }
}
