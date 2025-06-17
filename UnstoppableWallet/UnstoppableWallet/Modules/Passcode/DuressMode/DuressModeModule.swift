import SwiftUI

enum DuressModeModule {
    static func view(showParentSheet: Binding<Bool>) -> some View {
        let viewModel = DuressModeViewModel(
            biometryManager: Core.shared.biometryManager,
            accountManager: Core.shared.accountManager
        )
        return DuressModeIntroView(viewModel: viewModel, showParentSheet: showParentSheet)
    }
}
