import Foundation

struct ValetProxy: Identifiable, Hashable {
    let id = UUID()
    let url: String
    let target: String
    let isSecure: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ValetProxy, rhs: ValetProxy) -> Bool {
        return lhs.id == rhs.id
    }
}
