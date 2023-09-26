import Combine

class SecuritySettingsViewModel: ObservableObject {
    private let passcodeManager: PasscodeManager
    private let biometryManager: BiometryManager
    private let lockManager: LockManager
    private var cancellables = Set<AnyCancellable>()

    @Published var currentPasscodeLevel: Int
    @Published var isPasscodeSet: Bool
    @Published var isDuressPasscodeSet: Bool
    @Published var biometryType: BiometryType?

    @Published var isBiometryToggleOn: Bool {
        didSet {
            if isBiometryToggleOn != biometryManager.biometryEnabled, isPasscodeSet {
                set(biometryEnabled: isBiometryToggleOn)
            }
        }
    }

    init(passcodeManager: PasscodeManager, biometryManager: BiometryManager, lockManager: LockManager) {
        self.passcodeManager = passcodeManager
        self.biometryManager = biometryManager
        self.lockManager = lockManager

        currentPasscodeLevel = passcodeManager.currentPasscodeLevel
        isPasscodeSet = passcodeManager.isPasscodeSet
        isDuressPasscodeSet = passcodeManager.isDuressPasscodeSet
        biometryType = biometryManager.biometryType

        isBiometryToggleOn = biometryManager.biometryEnabled

        passcodeManager.$currentPasscodeLevel
            .sink { [weak self] in self?.currentPasscodeLevel = $0 }
            .store(in: &cancellables)
        passcodeManager.$isPasscodeSet
            .sink { [weak self] in self?.isPasscodeSet = $0 }
            .store(in: &cancellables)
        passcodeManager.$isDuressPasscodeSet
            .sink { [weak self] in self?.isDuressPasscodeSet = $0 }
            .store(in: &cancellables)
        biometryManager.$biometryType
            .sink { [weak self] in self?.biometryType = $0 }
            .store(in: &cancellables)
        biometryManager.$biometryEnabled
            .sink { [weak self] in self?.isBiometryToggleOn = $0 }
            .store(in: &cancellables)
    }

    func removePasscode() {
        do {
            try passcodeManager.removePasscode()
        } catch {
            print("Remove Passcode Error: \(error)")
        }
    }

    func removeDuressPasscode() {
        do {
            try passcodeManager.removeDuressPasscode()
        } catch {
            print("Remove Duress Passcode Error: \(error)")
        }
    }

    func set(biometryEnabled: Bool) {
        biometryManager.biometryEnabled = biometryEnabled
    }
}
