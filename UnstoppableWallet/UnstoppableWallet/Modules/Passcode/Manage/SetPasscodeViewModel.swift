import Combine

class SetPasscodeViewModel: ObservableObject {
    let passcodeLength = 6

    @Published var description: String = ""
    @Published var errorText: String = ""
    @Published var passcode: String = "" {
        didSet {
            if passcode.count == passcodeLength {
                Task {
                    try await Task.sleep(nanoseconds: 200_000_000)
                    await handlePasscodeChanged()
                }
            } else if passcode.count != 0 {
                errorText = ""
            }
        }
    }
    @Published var shakeTrigger: Int = 0

    let passcodeManager: PasscodeManager

    var finishSubject = PassthroughSubject<Void, Never>()

    private var enteredPasscode: String?

    init(passcodeManager: PasscodeManager) {
        self.passcodeManager = passcodeManager
        syncDescription()
    }

    var title: String { "" }
    var passcodeDescription: String { "" }
    var confirmDescription: String { "" }
    func onEnter(passcode _: String) {}
    func onCancel() {}

    @MainActor
    private func handlePasscodeChanged() {
        if let enteredPasscode {
            if enteredPasscode == passcode {
                onEnter(passcode: passcode)
            } else {
                self.enteredPasscode = nil
                passcode = ""
                syncDescription()
                errorText = "set_passcode.invalid_confirmation".localized
            }
        } else {
            enteredPasscode = passcode
            passcode = ""
            syncDescription()
        }
    }

    private func syncDescription() {
        description = enteredPasscode == nil ? passcodeDescription : confirmDescription
    }
}
