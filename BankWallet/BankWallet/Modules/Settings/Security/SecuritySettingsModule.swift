protocol ISecuritySettingsView: class {
    func set(title: String)
    func set(biometricUnlockOn: Bool)
    func set(biometryType: BiometryType)
    func set(backedUp: Bool)
    func showUnlinkConfirmation()
}

protocol ISecuritySettingsViewDelegate {
    func viewDidLoad()
    func didSwitch(biometricUnlockOn: Bool)
    func didTapEditPin()
    func didTapBackupWallet()
    func didTapUnlink()
    func didConfirmUnlink()
}

protocol ISecuritySettingsInteractor {
    var isBiometricUnlockOn: Bool { get }
    var biometryType: BiometryType { get }
    var isBackedUp: Bool { get }
    func set(biometricUnlockOn: Bool)
    func unlink()
}

protocol ISecuritySettingsInteractorDelegate: class {
    func didBackup()
    func didUnlink()
}

protocol ISecuritySettingsRouter {
    func showEditPin()
    func showSecretKey()
    func showGuestModule()
}
