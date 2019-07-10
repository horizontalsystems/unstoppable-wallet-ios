protocol ISecuritySettingsView: class {
    func set(title: String)
    func set(biometricUnlockOn: Bool)
    func set(biometryType: BiometryType)
    func set(backedUp: Bool)
    func set(isPinSet: Bool)
}

protocol ISecuritySettingsViewDelegate {
    func viewDidLoad()
    func didSwitch(biometricUnlockOn: Bool)
    func didTapEditPin()
    func didTapSetPin()
    func didTapManageAccounts()
}

protocol ISecuritySettingsInteractor {
    var nonBackedUpCount: Int { get }
    var isBiometricUnlockOn: Bool { get }
    var isPinSet: Bool { get }
    func getBiometryType()
    func set(biometricUnlockOn: Bool)
}

protocol ISecuritySettingsInteractorDelegate: class {
    func didUpdateNonBackedUp(count: Int)
    func didUpdate(isPinSet: Bool)
    func didGetBiometry(type: BiometryType)
    func onUnlock()
    func onCancelUnlock()
}

protocol ISecuritySettingsRouter {
    func showManageAccounts()
    func showSetPin()
    func showEditPin()
    func showUnlock()
}

enum SecuritySettingsUnlockType {
    case biometry(isOn: Bool)
}
