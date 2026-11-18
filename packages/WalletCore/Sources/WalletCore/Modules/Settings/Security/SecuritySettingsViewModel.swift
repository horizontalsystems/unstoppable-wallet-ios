import Combine
import Foundation

class SecuritySettingsViewModel: ObservableObject {
    private let passcodeManager = Core.shared.passcodeManager
    private let biometryManager = Core.shared.biometryManager
    private let lockManager = Core.shared.lockManager
    private let balanceHiddenManager = Core.shared.balanceHiddenManager
    private let securityManager = Core.shared.securityManager
    private let appStateManager = AppStateManager.instance

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

    @Published var spamFilterEnabled: Bool {
        didSet {
            securityManager.setSpamFilter(enabled: spamFilterEnabled)
        }
    }

    @Published private(set) var secureSendEnabled: Bool
    @Published private(set) var scamProtectionEnabled: Bool
    @Published private(set) var swapProtectionEnabled: Bool
    @Published private(set) var swapEnabled: Bool

    init() {
        currentPasscodeLevel = passcodeManager.currentPasscodeLevel
        isPasscodeSet = passcodeManager.isPasscodeSet
        isDuressPasscodeSet = passcodeManager.isDuressPasscodeSet
        biometryType = biometryManager.biometryType
        autoLockPeriod = lockManager.autoLockPeriod

        biometryEnabledType = biometryManager.biometryEnabledType
        balanceAutoHide = balanceHiddenManager.balanceAutoHide
        spamFilterEnabled = securityManager.spamFilterEnabled

        secureSendEnabled = securityManager.secureSendEnabled
        scamProtectionEnabled = securityManager.scamProtectionEnabled
        swapProtectionEnabled = securityManager.swapProtectionEnabled
        swapEnabled = appStateManager.swapEnabled

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

        securityManager.$secureSendEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.secureSendEnabled = $0 }
            .store(in: &cancellables)
        securityManager.$swapProtectionEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.swapProtectionEnabled = $0 }
            .store(in: &cancellables)
        securityManager.$scamProtectionEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.scamProtectionEnabled = $0 }
            .store(in: &cancellables)
        securityManager.$spamFilterEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.spamFilterEnabled = $0 }
            .store(in: &cancellables)

        appStateManager.$swapEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.swapEnabled = $0 }
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
            HudHelper.instance.show(banner: .disabled)
        } catch {
            print("Remove Duress Passcode Error: \(error)")
        }
    }

    func set(biometryEnabledType: BiometryManager.BiometryEnabledType) {
        biometryManager.biometryEnabledType = biometryEnabledType
    }

    func setScamProtection(enabled: Bool) {
        securityManager.setScamProtection(enabled: enabled)
    }

    func setSwapProtection(enabled: Bool) {
        securityManager.setSwapProtection(enabled: enabled)
    }
}
