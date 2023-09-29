import Combine
import HsExtensions
import LocalAuthentication
import UIKit

class BaseUnlockViewModel: ObservableObject {
    let passcodeLength = 6

    @Published var description: String = "unlock.passcode".localized
    @Published var errorText: String = ""
    @Published var passcode: String = "" {
        didSet {
            if passcode.count == passcodeLength {
                Task {
                    try await Task.sleep(nanoseconds: 200_000_000)
                    await handlePasscodeChanged()
                }
            }
        }
    }

    @Published var resolvedBiometryType: BiometryType?
    var biometryType: BiometryType?
    var biometryEnabled: Bool
    @Published var lockoutState: LockoutState {
        didSet {
            syncErrorText()
        }
    }
    @Published var shakeTrigger: Int = 0

    let finishSubject = PassthroughSubject<Void, Never>()
    let unlockWithBiometrySubject = PassthroughSubject<Void, Never>()

    let passcodeManager: PasscodeManager
    private let biometryManager: BiometryManager
    private let lockoutManager: LockoutManager
    private let blurManager: BlurManager
    private let biometryAllowed: Bool
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    init(passcodeManager: PasscodeManager, biometryManager: BiometryManager, lockoutManager: LockoutManager, blurManager: BlurManager, biometryAllowed: Bool) {
        self.passcodeManager = passcodeManager
        self.biometryManager = biometryManager
        self.lockoutManager = lockoutManager
        self.blurManager = blurManager
        self.biometryAllowed = biometryAllowed

        biometryType = biometryManager.biometryType
        biometryEnabled = biometryManager.biometryEnabled
        lockoutState = lockoutManager.lockoutState

        biometryManager.$biometryType
            .sink { [weak self] in
                self?.biometryType = $0
                self?.syncBiometryType()
            }
            .store(in: &cancellables)
        biometryManager.$biometryEnabled
            .sink { [weak self] in
                self?.biometryEnabled = $0
                self?.syncBiometryType()
            }
            .store(in: &cancellables)
        lockoutManager.$lockoutState
            .sink { [weak self] in
                self?.lockoutState = $0
                self?.syncBiometryType()
            }
            .store(in: &cancellables)

        syncErrorText()
        syncBiometryType()
    }

    private func syncBiometryType() {
        resolvedBiometryType = biometryEnabled && biometryAllowed && !lockoutState.isAttempted ? biometryType : nil
    }

    func isValid(passcode _: String) -> Bool { false }
    func onEnterValid(passcode _: String) {}
    func onBiometryUnlock() {}

    @MainActor
    private func handlePasscodeChanged() {
        if isValid(passcode: passcode) {
            onEnterValid(passcode: passcode)
            lockoutManager.didUnlock()
        } else {
            passcode = ""
            lockoutManager.didFailUnlock()

            shakeTrigger += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func syncErrorText() {
        switch lockoutState {
        case let .unlocked(attemptsLeft, maxAttempts):
            errorText = attemptsLeft == maxAttempts ? "" : "unlock.attempts_left".localized(String(attemptsLeft))
        default:
            errorText = ""
        }
    }

    func onAppear() {
        blurManager.isEnabled = false

        if resolvedBiometryType != nil {
            unlockWithBiometrySubject.send()
        }
    }

    func onDisappear() {
        blurManager.isEnabled = true
    }
}
