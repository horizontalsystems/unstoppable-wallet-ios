import Combine
import Foundation

class SecuritySettingsViewModel: ObservableObject {
    var premiumFeatures: [PremiumFeature] = PremiumCategory.defenseSystem.features

    private let passcodeManager = Core.shared.passcodeManager
    private let biometryManager = Core.shared.biometryManager
    private let lockManager = Core.shared.lockManager
    private let balanceHiddenManager = Core.shared.balanceHiddenManager
    private let securityManager = Core.shared.securityManager
    private let purchaseManager = Core.shared.purchaseManager

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

    @Published var featureEnabled: [PremiumFeature: Bool]
    @Published private(set) var premiumEnabled: Bool

    init() {
        currentPasscodeLevel = passcodeManager.currentPasscodeLevel
        isPasscodeSet = passcodeManager.isPasscodeSet
        isDuressPasscodeSet = passcodeManager.isDuressPasscodeSet
        biometryType = biometryManager.biometryType
        autoLockPeriod = lockManager.autoLockPeriod

        biometryEnabledType = biometryManager.biometryEnabledType
        balanceAutoHide = balanceHiddenManager.balanceAutoHide
        spamFilterEnabled = securityManager.spamFilterEnabled

        featureEnabled = [
            .secureSend: securityManager.secureSendEnabled,
            .swapProtection: securityManager.swapProtectionEnabled,
            .scamProtection: securityManager.scamProtectionEnabled,
        ]
        premiumEnabled = purchaseManager.hasActivePurchase

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
            .sink { [weak self] in self?.featureEnabled[.secureSend] = $0 }
            .store(in: &cancellables)
        securityManager.$swapProtectionEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.featureEnabled[.swapProtection] = $0 }
            .store(in: &cancellables)
        securityManager.$scamProtectionEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.featureEnabled[.scamProtection] = $0 }
            .store(in: &cancellables)
        securityManager.$spamFilterEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.spamFilterEnabled = $0 }
            .store(in: &cancellables)

        purchaseManager.$activeFeatures
            .receive(on: DispatchQueue.main)
            .sink { [weak self] features in
                guard let self else { return }
                premiumEnabled = premiumFeatures.allSatisfy { features.contains($0) }
            }
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

// Premium Features
extension SecuritySettingsViewModel {
    func isEnabled(_ feature: PremiumFeature) -> Bool {
        featureEnabled[feature] ?? false
    }

    func set(_ feature: PremiumFeature, enabled: Bool) {
        switch feature {
        case .swapProtection:
            securityManager.setSwapProtection(enabled: enabled)
        case .scamProtection:
            securityManager.setScamProtection(enabled: enabled)
        default:
            break
        }
    }
}
