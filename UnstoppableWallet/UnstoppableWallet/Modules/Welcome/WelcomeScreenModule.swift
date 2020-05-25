protocol IWelcomeScreenView: class {
    func set(appVersion: String)
}

protocol IWelcomeScreenViewDelegate {
    func viewDidLoad()
    func didTapCreate()
    func didTapRestore()
    func didTapPrivacy()
}

protocol IWelcomeScreenInteractor {
    var appVersion: String { get }
}

protocol IWelcomeScreenRouter {
    func showCreateWallet()
    func showRestoreWallet()
    func showPrivacySettings()
}
