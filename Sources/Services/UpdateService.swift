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
            
            // 3. Run seamless updater script
            try runUpdaterScript(dmgPath: targetURL)
            
        } catch {
            print("Update failed: \(error)")
            isDownloading = false
        }
    }

    private func runUpdaterScript(dmgPath: URL) throws {
        let scriptPath = FileManager.default.temporaryDirectory.appendingPathComponent("valetbar_updater.sh")
        
        let script = """
        #!/bin/bash
        PID=\(ProcessInfo.processInfo.processIdentifier)
        DMG_PATH="\(dmgPath.path)"
        MOUNT_POINT="/tmp/ValetBar_Update_Mount"
        APP_PATH="/Applications/ValetBar.app"
        
        # 1. Wait for app to terminate
        echo "Waiting for ValetBar (PID $PID) to quit..."
        while kill -0 $PID 2> /dev/null; do sleep 0.5; done
        
        # 2. Mount DMG
        echo "Mounting DMG..."
        hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" -nobrowse
        
        # 3. Replace App
        if [ -d "$MOUNT_POINT/ValetBar.app" ]; then
            echo "Replacing application..."
            rm -rf "$APP_PATH"
            cp -R "$MOUNT_POINT/ValetBar.app" "$APP_PATH"
        fi
        
        # 4. Cleanup
        hdiutil detach "$MOUNT_POINT"
        rm -f "$DMG_PATH"
        rm -f "$0" # Delete self
        
        # 5. Relaunch
        echo "Relaunching..."
        open "$APP_PATH"
        """
        
        try script.write(to: scriptPath, atomically: true, encoding: String.Encoding.utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)
        
        // Execute detached
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", scriptPath.path]
        try task.run()
        
        // Quit immediately to let the script proceed
        DispatchQueue.main.async {
            NSApplication.shared.terminate(nil)
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
