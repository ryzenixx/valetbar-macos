import Foundation

enum AppState {
    case running
    case stopped
    case error(String)
    case loading(String)
}

class ValetService: ObservableObject {
    private let cli = ValetCLI()
    
    func refreshData() async throws -> (state: AppState, proxies: [ValetProxy]) {
        async let runningTask = cli.getStatus()
        async let proxiesTask = cli.getProxies()
        
        do {
            let proxies = try await proxiesTask
            let running = try await runningTask
            
            if !running {
                return (.stopped, proxies)
            }
            return (.running, proxies)
            
        } catch ValetError.valetNotFound {
            return (.error("Valet not found"), [])
        } catch {
            return (.error(error.localizedDescription), [])
        }
    }
    
    func start() async throws {
        try await cli.startValet()
    }
    
    func restart() async throws {
        try await cli.restartValet()
    }
    
    func stop() async throws {
        try await cli.stopValet()
    }
}
