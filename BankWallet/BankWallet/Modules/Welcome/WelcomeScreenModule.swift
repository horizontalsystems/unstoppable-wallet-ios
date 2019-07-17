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

    func createWallet()
}

protocol IWelcomeScreenInteractorDelegate: class {
    func didCreateWallet()
}

protocol IWelcomeScreenRouter {
    func showMain()
    func showRestore(delegate: IRestoreDelegate)
}
