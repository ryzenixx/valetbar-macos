import SwiftUI
import AppKit

struct NativeSwitch: NSViewRepresentable {
    @Binding var isOn: Bool
    
    func makeNSView(context: Context) -> NSSwitch {
        let toggle = NSSwitch()
        toggle.target = context.coordinator
        toggle.action = #selector(Coordinator.valueChanged(_:))
        return toggle
    }
    
    func updateNSView(_ nsView: NSSwitch, context: Context) {
        if nsView.state != (isOn ? .on : .off) {
            nsView.state = isOn ? .on : .off
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: NativeSwitch
        
        init(_ parent: NativeSwitch) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: NSSwitch) {
            parent.isOn = (sender.state == .on)
        }
    }
}
