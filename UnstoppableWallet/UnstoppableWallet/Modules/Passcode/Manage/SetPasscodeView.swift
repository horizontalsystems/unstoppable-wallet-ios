import SwiftUI

struct SetPasscodeView: View {
    @ObservedObject var viewModel: SetPasscodeViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                PasscodeView(
                    maxDigits: viewModel.passcodeLength,
                    description: $viewModel.description,
                    errorText: $viewModel.errorText,
                    passcode: $viewModel.passcode,
                    biometryType: Binding(get: { nil }, set: { _ in }),
                    lockoutState: Binding(get: { .unlocked(attemptsLeft: Int.max, maxAttempts: Int.max) }, set: { _ in }),
                    randomEnabled: false
                )
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.cancel".localized) {
                    viewModel.onCancel()
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .onReceive(viewModel.finishSubject) {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .interactiveDismiss(canDismissSheet: false)
    }
}
