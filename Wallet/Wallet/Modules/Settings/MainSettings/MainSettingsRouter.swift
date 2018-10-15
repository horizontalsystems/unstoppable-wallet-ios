import UIKit

class MainSettingsRouter {
    weak var viewController: UIViewController?
}

extension MainSettingsRouter: IMainSettingsRouter {

    func showSecuritySettings() {
        viewController?.navigationController?.pushViewController(SettingsSecurityController(), animated: true)
    }

    func showImportWallet() {
    }

    func showBaseCurrencySettings() {
    }

    func showLanguageSettings() {
        viewController?.navigationController?.pushViewController(SettingsLanguageController(), animated: true)
    }

    func showAbout() {
    }

    func openAppLink() {
        if let url = URL(string: "http://horizontalsystems.io/") {
            UIApplication.shared.open(url)
        }
    }

    func reloadAppInterface() {
        if let window = UIApplication.shared.keyWindow {
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = MainRouter.module()
            })
        }
    }

}

extension MainSettingsRouter {

    static func module() -> UIViewController {
        let router = MainSettingsRouter()
        let interactor = MainSettingsInteractor(localStorage: App.shared.localStorage, wordsManager: App.shared.wordsManager, languageManager: App.shared.languageManager)
        let presenter = MainSettingsPresenter(router: router, interactor: interactor)
        let view = MainSettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
