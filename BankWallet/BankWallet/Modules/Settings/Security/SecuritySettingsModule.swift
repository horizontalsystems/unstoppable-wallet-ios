protocol ISecuritySettingsView: class {
    func refresh()

    func set(backupAlertVisible: Bool)
    func toggle(pinSet: Bool)
    func set(editPinVisible: Bool)
    func set(biometryVisible: Bool)
    func set(biometryType: BiometryType)
    func toggle(biometryEnabled: Bool)
    func show(error: Error)
}

protocol ISecuritySettingsViewDelegate {
    func viewDidLoad()
    func didTapManageAccounts()
    func didTapBlockchainSettings()
    func didSwitch(pinSet: Bool)
    func didTapEditPin()
    func didSwitch(biometryEnabled: Bool)
}

protocol ISecuritySettingsInteractor: AnyObject {
    var allBackedUp: Bool { get }
    var biometryType: BiometryType { get }
    var pinSet: Bool { get }
    var biometryEnabled: Bool { get set }
    func disablePin() throws
}

protocol ISecuritySettingsInteractorDelegate: class {
    func didUpdate(allBackedUp: Bool)
    func didUpdate(pinSet: Bool)
    func didUpdate(biometryType: BiometryType)
}

protocol ISecuritySettingsRouter {
    func showManageAccounts()
    func showBlockchainSettings()
    func showSetPin(delegate: ISetPinDelegate)
    func showEditPin()
    func showUnlock(delegate: IUnlockDelegate)
}
