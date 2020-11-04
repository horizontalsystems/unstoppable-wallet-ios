import UIKit
import ModuleKit
import CurrencyKit

class MainSettingsRouter {
    weak var viewController: UIViewController?
}

extension MainSettingsRouter: IMainSettingsRouter {

    func showManageAccounts() {
        viewController?.navigationController?.pushViewController(ManageAccountsRouter.module(), animated: true)
    }

    func showSecuritySettings() {
        viewController?.navigationController?.pushViewController(SecuritySettingsRouter.module(), animated: true)
    }

    func showAppStatus() {
        viewController?.navigationController?.pushViewController(AppStatusRouter.module(), animated: true)
    }

    func showExperimentalFeatures() {
        viewController?.navigationController?.pushViewController(ExperimentalFeaturesRouter.module(), animated: true)
    }

    func showNotificationSettings() {
        viewController?.navigationController?.pushViewController(NotificationSettingsRouter.module(), animated: true)
    }

    func showBaseCurrencySettings() {
        viewController?.navigationController?.pushViewController(App.shared.currencyKit.baseCurrencySettingsModule, animated: true)
    }

    func showLanguageSettings() {
        let module = LanguageSettingsRouter.module { MainModule.instance(selectedTab: .settings) }
        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func showTerms() {
        viewController?.navigationController?.pushViewController(TermsRouter.module(), animated: true)
    }

    func showShare(appWebPageLink: String) {
        let text = "settings_tell_friends.text".localized + "\n" + appWebPageLink
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: [])
        viewController?.present(activityViewController, animated: true, completion: nil)
    }

    func showContact() {
        viewController?.navigationController?.pushViewController(ContactRouter.module(), animated: true)
    }

    func open(link: String) {
        if let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }

    func reloadAppInterface() {
        UIApplication.shared.keyWindow?.set(newRootController: MainModule.instance(selectedTab: .settings))
    }

}

extension MainSettingsRouter {

    static func module() -> UIViewController {
        let router = MainSettingsRouter()
        let interactor = MainSettingsInteractor(
                backupManager: App.shared.backupManager,
                pinKit: App.shared.pinKit,
                termsManager: App.shared.termsManager,
                themeManager: App.shared.themeManager,
                systemInfoManager: App.shared.systemInfoManager,
                currencyKit: App.shared.currencyKit,
                appConfigProvider: App.shared.appConfigProvider,
                walletConnectSessionStore: App.shared.walletConnectSessionStore
        )
        let presenter = MainSettingsPresenter(router: router, interactor: interactor)
        let view = MainSettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
