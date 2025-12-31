import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: ValetViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var launchService = LaunchAtLoginService()
    @StateObject private var updateService = UpdateService()
    
    enum Screen {
        case dashboard
        case settings
    }
    
    @State private var currentScreen: Screen = .dashboard
    
    private var statusColor: Color {
        switch viewModel.appState {
        case .running: return .green
        case .stopped: return .gray
        case .loading: return .orange
        case .error: return .red
        }
    }
    
    private var statusText: String {
        switch viewModel.appState {
        case .running: return "RUNNING"
        case .stopped: return "STOPPED"
        case .loading(let text): return text
        case .error: return "ERROR"
        }
    }
    
    private var headerIcon: NSImage {
        if let resourcePath = Bundle.main.resourcePath {
            let iconPath = resourcePath + "/MenuBarIcon.png"
            if let image = NSImage(contentsOfFile: iconPath) {
                 image.isTemplate = true
                 return image
            }
        }
        return NSImage(systemSymbolName: "server.rack", accessibilityDescription: nil) ?? NSImage()
    }
    
    var body: some View {
        ZStack {
            if currentScreen == .dashboard {
                dashboardContent
                    .transition(.move(edge: .leading))
            } else {
                SettingsView(launchService: launchService, updateService: updateService) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentScreen = .dashboard
                    }
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentScreen)
        .background(WindowAccessor { window in
            guard let window = window else { return }
            if window.styleMask.contains(.resizable) {
                window.styleMask.remove(.resizable)
            }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
        })
        .background(CursorFixView())
        .onAppear {
            Task {
                await viewModel.loadData()
                await updateService.checkForUpdates()
            }
        }
    }
    
    var dashboardContent: some View {
        VStack(spacing: 0) {
            
            VStack(spacing: 12) {
                HStack {
                    Image(nsImage: headerIcon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22, height: 22)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Laravel Valet")
                            .font(.system(size: 14, weight: .bold))
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            Text(statusText)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button("Settings") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currentScreen = .settings
                            }
                        }
                        
                        Divider()
                        
                        Button("Quit Valet Bar") {
                            NSApplication.shared.terminate(nil)
                        }
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            if updateService.isUpdateAvailable {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                if case .loading(let text) = viewModel.appState {
                     HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(text.capitalized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 30)
                } else {
                    HStack(spacing: 10) {
                        if case .running = viewModel.appState {
                            ActionButton(icon: "stop.circle", label: "Stop") {
                                Task.detached { await viewModel.stopValet() }
                            }
                            
                            ActionButton(icon: "arrow.clockwise", label: "Restart") {
                                Task.detached { await viewModel.restartValet() }
                            }
                        } else {
                            ActionButton(icon: "play.circle", label: "Start") {
                                Task.detached { await viewModel.startValet() }
                            }
                        }
                        
                        ActionButton(icon: "arrow.triangle.2.circlepath", label: "Refresh") {
                            Task.detached { await viewModel.loadData() }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .background(.thinMaterial)
            
            Divider()
            
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search sites...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(10)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.filteredProxies.isEmpty {
                        Text("No proxies found")
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(viewModel.filteredProxies) { proxy in
                            ProxyRow(proxy: proxy)
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
            }
            
            Divider()
            
            VStack(spacing: 4) {
                Text(AppConfig.appName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Version \(AppConfig.appVersion)")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                
                Button("More information") {
                    if let url = URL(string: "https://github.com/ryzenixx/valetbar-macos") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
                .font(.caption2)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isHovered ? Color.white.opacity(0.1) : Color.clear)
            .background(.regularMaterial)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct ProxyRow: View {
    let proxy: ValetProxy
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(proxy.isSecure ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: proxy.isSecure ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 12))
                    .foregroundColor(proxy.isSecure ? .green : .red)
                    .frame(width: 14)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(proxy.url)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Text(proxy.target)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isHovered {
                Button(action: {
                    var domain = proxy.url
                    if !domain.hasSuffix(".test") { domain += ".test" }
                    if let url = URL(string: "https://\(domain)") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Image(systemName: "safari")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                        .padding(6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            var domain = proxy.url
            if !domain.hasSuffix(".test") { domain += ".test" }
            if let url = URL(string: "https://\(domain)") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
