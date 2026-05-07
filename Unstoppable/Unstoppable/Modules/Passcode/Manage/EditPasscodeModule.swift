import SwiftUI

enum EditPasscodeModule {
    static func editPasscodeView(showParentSheet: Binding<Bool>) -> some View {
        let viewModel = EditPasscodeViewModel(passcodeManager: Core.shared.passcodeManager)
        return SetPasscodeView(viewModel: viewModel, showParentSheet: showParentSheet)
    }

    static func editDuressPasscodeView(showParentSheet: Binding<Bool>) -> some View {
        let viewModel = EditDuressPasscodeViewModel(passcodeManager: Core.shared.passcodeManager)
        return SetPasscodeView(viewModel: viewModel, showParentSheet: showParentSheet)
    }
}
