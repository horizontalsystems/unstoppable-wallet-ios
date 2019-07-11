protocol ISecuritySettingsView: class {
    func set(title: String)
    func set(biometryType: BiometryType)
    func set(backedUp: Bool)
    func set(isPinSet: Bool)
    func set(biometricUnlockOn: Bool)
    func show(error: Error)
}

protocol ISecuritySettingsViewDelegate {
    func viewDidLoad()
    func didTapManageAccounts()
    func didSwitch(isPinSet: Bool)
    func didTapEditPin()
    func didSwitch(biometricUnlockOn: Bool)
}

protocol ISecuritySettingsInteractor {
    var nonBackedUpCount: Int { get }
    var biometryType: BiometryType { get }
    var isPinSet: Bool { get }
    var isBiometricUnlockOn: Bool { get }
    func disablePin() throws
    func set(biometricUnlockOn: Bool)
}

protocol ISecuritySettingsInteractorDelegate: class {
    func didUpdateNonBackedUp(count: Int)
    func didUpdate(isPinSet: Bool)
    func didUpdate(biometryType: BiometryType)
}

protocol ISecuritySettingsRouter {
    func showManageAccounts()
    func showSetPin(delegate: ISetPinDelegate)
    func showEditPin()
    func showUnlock(delegate: IUnlockDelegate)
}

enum SecuritySettingsUnlockType {
    case biometry(isOn: Bool)
}
