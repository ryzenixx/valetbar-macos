import Foundation

enum ValetError: Error {
    case commandFailed(String)
    case valetNotFound
    case parsingError
}

class ValetCLI {
    
    private let commonPaths = [
        "/usr/local/bin/valet",
        "/opt/homebrew/bin/valet",
        "\(FileManager.default.homeDirectoryForCurrentUser.path)/.composer/vendor/bin/valet",
        "\(FileManager.default.homeDirectoryForCurrentUser.path)/.config/composer/vendor/bin/valet"
    ]
    
    private var cachedValetPath: String?
    
    private func getValetPath() -> String {
        if let path = cachedValetPath { return path }
        
        let pathsToCheck = [
            "/opt/homebrew/bin/valet",
            "/usr/local/bin/valet",
            "\(FileManager.default.homeDirectoryForCurrentUser.path)/.composer/vendor/bin/valet",
            "\(FileManager.default.homeDirectoryForCurrentUser.path)/.config/composer/vendor/bin/valet"
        ]
        
        for path in pathsToCheck {
            if FileManager.default.fileExists(atPath: path) {
                print("Found valet at: \(path)")
                cachedValetPath = path
                return path
            }
        }
        return "valet"
    }
    
    private func executeValetCommand(_ arguments: [String]) async throws -> String {
        let valetPath = getValetPath()
        let process = Process()
        
        var env = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        env["HOME"] = home
        
        let newPath = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\(home)/.composer/vendor/bin"
        env["PATH"] = newPath
        
        process.environment = env
        
        if valetPath.hasPrefix("/") {
            process.executableURL = URL(fileURLWithPath: valetPath)
            process.arguments = arguments
        } else {
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", "valet " + arguments.joined(separator: " ")]
        }
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                print("Output: \(output)")
                
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    if output.contains("command not found") {
                        continuation.resume(throwing: ValetError.valetNotFound)
                    } else {
                        continuation.resume(throwing: ValetError.commandFailed(output))
                    }
                }
            } catch {
                print("Execution failed: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getStatus() async throws -> Bool {
        do {
            let output = try await executeValetCommand(["status"])
            return output.contains("Nginx")
        } catch {
            return false
        }
    }
    
    func startValet() async throws {
        _ = try await executeValetCommand(["start"])
    }
    
    func restartValet() async throws {
        _ = try await executeValetCommand(["restart"])
    }
    
    func stopValet() async throws {
        _ = try await executeValetCommand(["stop"])
    }
    
    func getProxies() async throws -> [ValetProxy] {
        let output = try await executeValetCommand(["proxies"])
        return parseProxiesOutput(output)
    }
    
    internal func parseProxiesOutput(_ output: String) -> [ValetProxy] {
        var proxies: [ValetProxy] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("+") || trimmed.contains("Site") {
                continue
            }
            if !trimmed.hasPrefix("|") { continue }
            
            let parts = trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            
            if parts.count >= 4 {
                let url = parts[1]
                let ssl = parts[2]
                let target = parts[3]
                
                if !url.isEmpty && !target.isEmpty {
                    let isSecure = (ssl == "X")
                    let proxy = ValetProxy(url: url, target: target, isSecure: isSecure)
                    proxies.append(proxy)
                }
            }
        }
        return proxies
    }
}
