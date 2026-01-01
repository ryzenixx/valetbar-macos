import SwiftUI
import Combine

@MainActor
class ValetViewModel: ObservableObject {
    @Published var proxies: [ValetProxy] = []
    @Published var appState: AppState = .loading("LOADING...")
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    private var isActionInProgress = false
    
    private let service = ValetService()
    
    var filteredProxies: [ValetProxy] {
        if searchText.isEmpty {
            return proxies
        }
        return proxies.filter { $0.url.localizedCaseInsensitiveContains(searchText) }
    }
    
    func loadData() async {
        if isActionInProgress { return }
        
        if case .loading = appState {
        } else if proxies.isEmpty {
           appState = .loading("LOADING...")
        }
        
        errorMessage = nil
        do {
            let (state, proxies) = try await service.refreshData()
            if !isActionInProgress {
                self.appState = state
                self.proxies = proxies
            }
        } catch {
            if !isActionInProgress {
                self.appState = .error(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func startValet() async {
        guard !isActionInProgress else { return }
        isActionInProgress = true
        appState = .loading("STARTING...")
        
        do {
            try await service.start()
            self.appState = .running
            await loadProxiesOnly()
        } catch {
            self.errorMessage = "Failed to start: \(error.localizedDescription)"
            self.appState = .error(error.localizedDescription)
        }
        
        isActionInProgress = false
    }
    
    func restartValet() async {
        guard !isActionInProgress else { return }
        isActionInProgress = true
        appState = .loading("RESTARTING...")
        
        do {
            try await service.restart()
            self.appState = .running
            await loadProxiesOnly()
        } catch {
            self.errorMessage = "Failed to restart: \(error.localizedDescription)"
            self.appState = .error(error.localizedDescription)
        }
        
        isActionInProgress = false
    }
    
    func stopValet() async {
        guard !isActionInProgress else { return }
        isActionInProgress = true
        appState = .loading("STOPPING...")
        
        do {
            try await service.stop()
            self.appState = .stopped
            await loadProxiesOnly()
        } catch {
            self.errorMessage = "Failed to stop: \(error.localizedDescription)"
            self.appState = .error(error.localizedDescription)
        }
        
        isActionInProgress = false
    }
    
    func addProxy(domain: String, target: String, secure: Bool) async -> Bool {
        guard !isActionInProgress else { return false }
        isActionInProgress = true
        appState = .loading("ADDING...")
        
        do {
            try await service.addProxy(domain: domain, target: target, secure: secure)
            
            // Refresh list
            await loadProxiesOnly()
            
            // Re-check status
            let (state, _) = try await service.refreshData()
            self.appState = state
            
            isActionInProgress = false
            return true
        } catch {
            self.errorMessage = "Failed to add proxy: \(error.localizedDescription)"
            self.appState = .error(error.localizedDescription)
            isActionInProgress = false
            return false
        }
    }
    
    func removeProxy(proxy: ValetProxy) async {
        guard !isActionInProgress else { return }
        isActionInProgress = true
        appState = .loading("REMOVING...")
        
        let domain = proxy.url.replacingOccurrences(of: ".test", with: "")
        
        do {
            try await service.removeProxy(domain: domain)
            
            await loadProxiesOnly()
            
            let (state, _) = try await service.refreshData()
            self.appState = state
            
        } catch {
            self.errorMessage = "Failed to remove proxy: \(error.localizedDescription)"
            self.appState = .error(error.localizedDescription)
        }
        
        isActionInProgress = false
    }
    
    private func loadProxiesOnly() async {
        do {
            let (_, proxies) = try await service.refreshData()
            self.proxies = proxies
        } catch {
            print("Failed to refresh proxies: \(error)")
        }
    }
}
