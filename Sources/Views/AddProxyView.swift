import SwiftUI

struct AddProxyView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ValetViewModel
    
    @State private var domain: String = ""
    @State private var target: String = ""
    @State private var isSecure: Bool = false
    @State private var isSaving: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Proxy")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Domain")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("my.frontend", text: $domain)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                if !domain.isEmpty {
                    (Text("Will be available at ") + Text("\(isSecure ? "https" : "http")://\(domain).test").bold())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Target")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("http://")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                        .padding(.leading, 8)
                    
                    TextField("127.0.0.1:3000", text: $target)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            
            Toggle("Secure (HTTPS)", isOn: $isSecure)
                .toggleStyle(.switch)
                .controlSize(.small)
            
            Divider()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .disabled(isSaving)
                
                Spacer()
                
                Button("Create") {
                    createProxy()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(domain.isEmpty || target.isEmpty || isSaving)
            }
        }
        .padding()
        .frame(width: 300)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow, state: .active))
        .presentationBackground(.clear)
    }
    
    private func createProxy() {
        isSaving = true
        
        // Auto-prepend http:// if missing
        let finalTarget = target.hasPrefix("http") ? target : "http://\(target)"
        
        Task {
            let success = await viewModel.addProxy(domain: domain, target: finalTarget, secure: isSecure)
            isSaving = false
            if success {
                dismiss()
            }
        }
    }
}
