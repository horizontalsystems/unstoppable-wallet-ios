import PinKit

protocol ISecuritySettingsView: AnyObject {
    func refresh()

    func set(backupAlertVisible: Bool)
    func toggle(pinSet: Bool)
    func set(editPinVisible: Bool)
    func set(biometryVisible: Bool)
    func set(biometryType: BiometryType?)
    func toggle(biometryEnabled: Bool)
    func show(error: Error)
}

protocol ISecuritySettingsViewDelegate {
    func viewDidLoad()
    func didSwitch(pinSet: Bool)
    func didTapEditPin()
    func didSwitch(biometryEnabled: Bool)
    func didTapPrivacy()
}

protocol ISecuritySettingsInteractor: AnyObject {
    var allBackedUp: Bool { get }
    var biometryType: BiometryType? { get }
    var pinSet: Bool { get }
    var biometryEnabled: Bool { get set }
    func disablePin() throws
}

protocol ISecuritySettingsInteractorDelegate: AnyObject {
    func didUpdate(allBackedUp: Bool)
    func didUpdate(pinSet: Bool)
    func didUpdate(biometryType: BiometryType)
}

protocol ISecuritySettingsRouter {
    func showSetPin(delegate: ISetPinDelegate)
    func showEditPin()
    func showUnlock(delegate: IUnlockDelegate)
    func showPrivacy()
}
