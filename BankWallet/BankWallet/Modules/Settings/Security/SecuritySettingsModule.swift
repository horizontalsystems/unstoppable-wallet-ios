protocol ISecuritySettingsView: class {
    func set(title: String)
    func set(biometricUnlockOn: Bool)
    func set(biometryType: BiometryType)
    func set(backedUp: Bool)
}

protocol ISecuritySettingsViewDelegate {
    func viewDidLoad()
    func didSwitch(biometricUnlockOn: Bool)
    func didTapEditPin()
    func didTapBackupWallet()
    func didTapUnlink()
}

protocol ISecuritySettingsInteractor {
    var isBiometricUnlockOn: Bool { get }
    var isBackedUp: Bool { get }
    func getBiometryType()
    func set(biometricUnlockOn: Bool)
}

protocol ISecuritySettingsInteractorDelegate: class {
    func didBackup()
    func didGetBiometry(type: BiometryType)
}

protocol ISecuritySettingsRouter {
    func showEditPin()
    func showSecretKey()
    func showUnlink()
}
