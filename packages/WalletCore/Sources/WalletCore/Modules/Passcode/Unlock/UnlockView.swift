import LocalAuthentication
import SwiftUI

struct AppUnlockView: View {
    @StateObject private var viewModel = AppUnlockViewModel(biometryAllowed: true)

    var body: some View {
        UnlockView(viewModel: viewModel)
    }
}

struct UnlockView: View {
    @ObservedObject var viewModel: BaseUnlockViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeView {
            PasscodeView(
                maxDigits: viewModel.passcodeLength,
                description: $viewModel.description,
                errorText: $viewModel.errorText,
                passcode: $viewModel.passcode,
                biometryType: $viewModel.resolvedBiometryType,
                lockoutState: $viewModel.lockoutState,
                shakeTrigger: $viewModel.shakeTrigger,
                randomEnabled: true,
                onTapBiometry: {
                    unlockWithBiometry()
                }
            )
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onReceive(viewModel.finishSubject) {
            presentationMode.wrappedValue.dismiss()
        }
        .onReceive(viewModel.unlockWithBiometrySubject) {
            unlockWithBiometry()
        }
    }

    private func unlockWithBiometry() {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "unlock.biometry_reason".localized) { success, _ in
            if success {
                DispatchQueue.main.async {
                    viewModel.onBiometryUnlock()
                }
            }
        }
    }
}
