import SwiftUI

struct EditPasscodeModule {
    static func editPasscodeView() -> some View {
        let viewModel = EditPasscodeViewModel(passcodeManager: App.shared.passcodeManager)
        return SetPasscodeView(viewModel: viewModel)
    }

    static func editDuressPasscodeView() -> some View {
        let viewModel = EditDuressPasscodeViewModel(passcodeManager: App.shared.passcodeManager)
        return SetPasscodeView(viewModel: viewModel)
    }
}
