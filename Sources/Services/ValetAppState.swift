import SwiftUI

@MainActor
class ValetAppState: ObservableObject {
    let viewModel = ValetViewModel()
    let updaterController = UpdaterController()
}
