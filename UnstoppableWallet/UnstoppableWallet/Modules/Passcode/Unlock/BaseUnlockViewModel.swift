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
            let passcode = passcode
            if passcode.count == passcodeLength {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
                    self?.handleEntered(passcode: passcode)
                }
            }
        }
    }

    @Published var resolvedBiometryType: BiometryType?
    var biometryType: BiometryType?
    var biometryEnabledType: BiometryManager.BiometryEnabledType
    @Published var lockoutState: LockoutState {
        didSet {
            syncErrorText()
        }
    }

    @Published var shakeTrigger: Int = 0

    let finishSubject = PassthroughSubject<Void, Never>()
    let unlockWithBiometrySubject = PassthroughSubject<Void, Never>()

    let passcodeManager = Core.shared.passcodeManager
    private let biometryManager = Core.shared.biometryManager
    private let lockoutManager = Core.shared.lockoutManager
    private let biometryAllowed: Bool
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    init(biometryAllowed: Bool) {
        self.biometryAllowed = biometryAllowed

        biometryType = biometryManager.biometryType
        biometryEnabledType = biometryManager.biometryEnabledType
        lockoutState = lockoutManager.lockoutState

        biometryManager.$biometryType
            .sink { [weak self] in
                self?.biometryType = $0
                self?.syncBiometryType()
            }
            .store(in: &cancellables)
        biometryManager.$biometryEnabledType
            .sink { [weak self] in
                self?.biometryEnabledType = $0
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
        resolvedBiometryType = biometryEnabledType.isEnabled && biometryAllowed && !lockoutState.isAttempted ? biometryType : nil
    }

    func isValid(passcode: String) -> Bool { false }
    func onEnterValid(passcode _: String) {}
    func onBiometryUnlock() {}

    private func handleEntered(passcode: String) {
        if isValid(passcode: passcode) {
            onEnterValid(passcode: passcode)
            lockoutManager.didUnlock()
        } else {
            self.passcode = ""
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
        if resolvedBiometryType != nil, biometryEnabledType.isAuto {
            unlockWithBiometrySubject.send()
        }
    }
}
