import SwiftUI

struct DuressModeModule {
    static func view(showParentSheet: Binding<Bool>) -> some View {
        let viewModel = DuressModeViewModel(
            biometryManager: App.shared.biometryManager,
            accountManager: App.shared.accountManager
        )
        return DuressModeIntroView(viewModel: viewModel, showParentSheet: showParentSheet)
    }
}
