import Combine

class SecuritySettingsViewModel: ObservableObject {
    private let passcodeManager: PasscodeManager
    private let biometryManager: BiometryManager
    private let lockManager: LockManager
    private let balanceHiddenManager: BalanceHiddenManager
    private var cancellables = Set<AnyCancellable>()

    @Published var currentPasscodeLevel: Int
    @Published var isPasscodeSet: Bool
    @Published var isDuressPasscodeSet: Bool
    @Published var biometryType: BiometryType?

    @Published var autoLockPeriod: AutoLockPeriod {
        didSet {
            lockManager.autoLockPeriod = autoLockPeriod
        }
    }

    @Published var biometryEnabledType: BiometryManager.BiometryEnabledType {
        didSet {
            if biometryEnabledType != biometryManager.biometryEnabledType, isPasscodeSet {
                set(biometryEnabledType: biometryEnabledType)
            }
        }
    }

    @Published var balanceAutoHide: Bool {
        didSet {
            balanceHiddenManager.set(balanceAutoHide: balanceAutoHide)
        }
    }

    init(passcodeManager: PasscodeManager, biometryManager: BiometryManager, lockManager: LockManager, balanceHiddenManager: BalanceHiddenManager) {
        self.passcodeManager = passcodeManager
        self.biometryManager = biometryManager
        self.lockManager = lockManager
        self.balanceHiddenManager = balanceHiddenManager

        currentPasscodeLevel = passcodeManager.currentPasscodeLevel
        isPasscodeSet = passcodeManager.isPasscodeSet
        isDuressPasscodeSet = passcodeManager.isDuressPasscodeSet
        biometryType = biometryManager.biometryType
        autoLockPeriod = lockManager.autoLockPeriod

        biometryEnabledType = biometryManager.biometryEnabledType
        balanceAutoHide = balanceHiddenManager.balanceAutoHide

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
        biometryManager.$biometryEnabledType
            .sink { [weak self] in self?.biometryEnabledType = $0 }
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

    func set(biometryEnabledType: BiometryManager.BiometryEnabledType) {
        biometryManager.biometryEnabledType = biometryEnabledType
    }
}
