import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: ValetViewModel
    @ObservedObject var updaterController: UpdaterController
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var launchService = LaunchAtLoginService()
    
    enum Screen {
        case dashboard
        case settings
    }
    
    @State private var currentScreen: Screen = .dashboard
    @State private var showAddProxy = false
    @State private var showDeleteConfirmation = false
    @State private var proxyToDelete: ValetProxy?
    
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
        // Try Bundle.module (Dev/Xcode - DEBUG ONLY)
        #if DEBUG
        if let moduleUrl = Bundle.module.url(forResource: "Assets/MenuBarIcon", withExtension: "png"),
           let image = NSImage(contentsOf: moduleUrl) {
            image.isTemplate = true
            return image
        }
        #endif
        
        // Try Bundle.main (Production/Manual Build)
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
                SettingsView(launchService: launchService, updaterController: updaterController) {
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
            window.backgroundColor = .clear
            window.isOpaque = false
        })
        .background(CursorFixView())
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow, state: .active))
        .onAppear {
            Task {
                await viewModel.loadData()
                // Updater checks automatically via Sparkle
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
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currentScreen = .settings
                            }
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        Divider()
                        
                        Button {
                            NSApplication.shared.terminate(nil)
                        } label: {
                            Label("Quit Valet Bar", systemImage: "power")
                        }
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            if updaterController.canCheckForUpdates {
                                // TODO : Logic to show red dot if update available is not directly exposed by canCheckForUpdates
                                // TODO : Sparkle handles its own UI, so we can simplify for now or implement SPUUserDriverDelegate for custom UI
                                // TODO : For V1, we rely on Sparkle's window popping up.
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
            
            // Search Bar & Add Button
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    TextField("Search proxies...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(10)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(8)
                
                Button(action: {
                    showAddProxy = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help("Add New Proxy")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .sheet(isPresented: $showAddProxy) {
                AddProxyView(viewModel: viewModel)
            }
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.filteredProxies.isEmpty {
                        Text("No proxies found")
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        HStack {
                            Text("\(viewModel.filteredProxies.count) \(viewModel.filteredProxies.count == 1 ? "PROXY" : "PROXIES")")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        
                        ForEach(viewModel.filteredProxies) { proxy in
                            ProxyRow(proxy: proxy)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        proxyToDelete = proxy
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete Proxy", systemImage: "trash")
                                    }
                                }
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
            }
            .alert("Delete Proxy", isPresented: $showDeleteConfirmation, presenting: proxyToDelete) { proxy in
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.removeProxy(proxy: proxy)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { proxy in
                Text("Are you sure you want to delete the proxy for \"\(proxy.url)\"? This action cannot be undone.")
            }
            
        }
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
