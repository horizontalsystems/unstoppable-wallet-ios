import SwiftUI

struct SetPasscodeView: View {
    @ObservedObject var viewModel: SetPasscodeViewModel
    @Binding var showParentSheet: Bool
    var showClose: Bool = true

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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if showClose {
                    Button(action: {
                        viewModel.onCancel()
                        showParentSheet = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
        .onReceive(viewModel.finishSubject) {
            showParentSheet = false
        }
    }
}
