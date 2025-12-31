import SwiftUI

struct SettingsView: View {
    @ObservedObject var launchService: LaunchAtLoginService
    @ObservedObject var updaterController: UpdaterController
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(4)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Text("Settings")
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Updates Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("UPDATES")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        Button(action: {
                            updaterController.checkForUpdates()
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.primary)
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Check for Updates")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("Current Version: \(AppConfig.appVersion)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .padding(12)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // General Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GENERAL")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "arrow.up.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                                Text("Launch at Login")
                                    .font(.system(size: 13))
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { launchService.isEnabled },
                                    set: { _ in launchService.toggle() }
                                ))
                                .labelsHidden()
                                .toggleStyle(.switch)
                            }
                            .padding(12)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(20)
            }
            
            Spacer()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .background(CursorFixView())
    }
}
