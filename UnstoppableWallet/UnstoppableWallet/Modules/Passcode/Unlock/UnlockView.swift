import LocalAuthentication
import SwiftUI

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
        .onDisappear {
            viewModel.onDisappear()
        }
        .onReceive(viewModel.finishSubject) { reloadApp in
            if reloadApp {
                UIApplication.shared.windows.first { $0.isKeyWindow }?.set(newRootController: MainModule.instance())
            } else {
                presentationMode.wrappedValue.dismiss()
            }
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
                    let shouldDismiss = viewModel.onBiometryUnlock()

                    if shouldDismiss {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
