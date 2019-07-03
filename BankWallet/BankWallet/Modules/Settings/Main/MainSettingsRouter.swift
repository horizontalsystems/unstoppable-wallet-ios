import UIKit

class MainSettingsRouter {
    weak var viewController: UIViewController?
}

extension MainSettingsRouter: IMainSettingsRouter {

    func showSecuritySettings() {
        viewController?.navigationController?.pushViewController(SecuritySettingsRouter.module(), animated: true)
    }

    func showRestore() {
        viewController?.present(RestoreRouter.module(), animated: true)
    }

    func showBaseCurrencySettings() {
        viewController?.navigationController?.pushViewController(BaseCurrencySettingsRouter.module(), animated: true)
    }

    func showLanguageSettings() {
        viewController?.navigationController?.pushViewController(LanguageSettingsRouter.module(), animated: true)
    }

    func showAbout() {
        viewController?.navigationController?.pushViewController(AboutSettingsRouter.module(), animated: true)
    }

    func openAppLink() {
        if let url = URL(string: "http://horizontalsystems.io/") {
            UIApplication.shared.open(url)
        }
    }

    func reloadAppInterface() {
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module(selectedTab: .settings))
    }

}

extension MainSettingsRouter {

    static func module() -> UIViewController {
        let router = MainSettingsRouter()
        let interactor = MainSettingsInteractor(localStorage: App.shared.localStorage, accountManager: App.shared.accountManager, languageManager: App.shared.languageManager, systemInfoManager: App.shared.systemInfoManager, currencyManager: App.shared.currencyManager)
        let presenter = MainSettingsPresenter(router: router, interactor: interactor)
        let view = MainSettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
