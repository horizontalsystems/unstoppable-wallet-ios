protocol IWelcomeScreenView: class {
    func set(appVersion: String)
}

protocol IWelcomeScreenViewDelegate {
    func viewDidLoad()
    func didTapCreate()
    func didTapRestore()
}

protocol IWelcomeScreenInteractor {
    var appVersion: String { get }
}

protocol IWelcomeScreenRouter {
    func showMain()
    func showCreateWallet()
    func showRestore(delegate: IRestoreDelegate)
}
