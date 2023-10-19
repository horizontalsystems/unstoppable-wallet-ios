import SwiftUI

struct EditPasscodeModule {
    static func editPasscodeView(showParentSheet: Binding<Bool>) -> some View {
        let viewModel = EditPasscodeViewModel(passcodeManager: App.shared.passcodeManager)
        return SetPasscodeView(viewModel: viewModel, showParentSheet: showParentSheet)
    }

    static func editDuressPasscodeView(showParentSheet: Binding<Bool>) -> some View {
        let viewModel = EditDuressPasscodeViewModel(passcodeManager: App.shared.passcodeManager)
        return SetPasscodeView(viewModel: viewModel, showParentSheet: showParentSheet)
    }
}
