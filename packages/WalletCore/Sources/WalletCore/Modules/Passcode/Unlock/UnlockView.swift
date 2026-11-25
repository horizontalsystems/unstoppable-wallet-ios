import LocalAuthentication
import SwiftUI

struct AppUnlockView: View {
    @StateObject private var viewModel = AppUnlockViewModel(biometryAllowed: true)

    var body: some View {
        ThemeNavigationStack {
            UnlockView(viewModel: viewModel, headerTopInset: .margin48)
                .toolbar(.visible, for: .navigationBar)
                .toolbar {
                    // an empty item gives the bar content, so the system shows it and reserves its height
                    ToolbarItem(placement: .principal) {
                        Color.clear
                            .accessibilityHidden(true)
                    }
                }
        }
    }
}

struct UnlockView: View {
    @ObservedObject var viewModel: BaseUnlockViewModel
    var headerTopInset: CGFloat = .margin32

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeView {
            PasscodeView(
                maxDigits: viewModel.passcodeLength,
                title: viewModel.title,
                description: "",
                errorText: $viewModel.errorText,
                errorIdentifier: TestTags.pinAttemptsLeft,
                passcode: $viewModel.passcode,
                biometryType: $viewModel.resolvedBiometryType,
                lockoutState: $viewModel.lockoutState,
                shakeTrigger: $viewModel.shakeTrigger,
                randomEnabled: true,
                headerTopInset: headerTopInset,
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
