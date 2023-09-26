import SwiftUI

struct CreatePasscodeModule {
    static func createPasscodeView(reason: CreatePasscodeReason, onCreate: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        let viewModel = CreatePasscodeViewModel(
            passcodeManager: App.shared.passcodeManager,
            reason: reason,
            onCreate: onCreate,
            onCancel: onCancel
        )

        return SetPasscodeView(viewModel: viewModel)
    }

    static func createDuressPasscodeView() -> some View {
        let viewModel = CreateDuressPasscodeViewModel(
            passcodeManager: App.shared.passcodeManager
        )

        return SetPasscodeView(viewModel: viewModel)
    }

    enum CreatePasscodeReason: Hashable, Identifiable {
        case regular
        case biometry(type: BiometryType)
        case duress

        var description: String {
            switch self {
            case .regular: return "create_passcode.description".localized
            case .biometry(let type): return "create_passcode.description.biometry".localized(type.title)
            case .duress: return "create_passcode.description.duress_mode".localized
            }
        }

        var id: Self {
            self
        }
    }
}
