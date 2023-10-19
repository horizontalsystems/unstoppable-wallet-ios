import SwiftUI

struct SetPasscodeView: View {
    @ObservedObject var viewModel: SetPasscodeViewModel
    @Binding var showParentSheet: Bool

    var body: some View {
        ThemeView {
            PasscodeView(
                maxDigits: viewModel.passcodeLength,
                description: $viewModel.description,
                errorText: $viewModel.errorText,
                passcode: $viewModel.passcode,
                biometryType: Binding(get: { nil }, set: { _ in }),
                lockoutState: Binding(get: { .unlocked(attemptsLeft: Int.max, maxAttempts: Int.max) }, set: { _ in }),
                shakeTrigger: $viewModel.shakeTrigger,
                randomEnabled: false
            )
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.cancel".localized) {
                viewModel.onCancel()
                showParentSheet = false
            }
        }
        .onReceive(viewModel.finishSubject) {
            showParentSheet = false
        }
    }
}
