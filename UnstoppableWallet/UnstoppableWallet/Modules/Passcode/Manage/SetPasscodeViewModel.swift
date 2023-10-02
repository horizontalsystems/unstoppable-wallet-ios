import Combine
import UIKit

class SetPasscodeViewModel: ObservableObject {
    let passcodeLength = 6

    @Published var description: String = ""
    @Published var errorText: String = ""
    @Published var passcode: String = "" {
        didSet {
            let passcode = passcode
            if passcode.count == passcodeLength {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
                    self?.handleEntered(passcode: passcode)
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
    func isCurrent(passcode: String) -> Bool { false }
    func onEnter(passcode _: String) {}
    func onCancel() {}

    private func handleEntered(passcode: String) {
        if let enteredPasscode {
            if enteredPasscode == passcode {
                onEnter(passcode: passcode)
            } else {
                self.enteredPasscode = nil
                self.passcode = ""
                syncDescription()
                errorText = "set_passcode.invalid_confirmation".localized
            }
        } else if passcodeManager.has(passcode: passcode) && !isCurrent(passcode: passcode) {
            self.passcode = ""
            errorText = "set_passcode.already_used".localized

            shakeTrigger += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } else {
            enteredPasscode = passcode
            self.passcode = ""
            syncDescription()
        }
    }

    private func syncDescription() {
        description = enteredPasscode == nil ? passcodeDescription : confirmDescription
    }
}
