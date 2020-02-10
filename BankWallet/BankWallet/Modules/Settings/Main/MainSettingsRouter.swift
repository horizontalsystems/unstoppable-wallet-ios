import UIKit
import LanguageKit
import CurrencyKit

class MainSettingsRouter {
    weak var viewController: UIViewController?
}

extension MainSettingsRouter: IMainSettingsRouter {

    func showSecuritySettings() {
        viewController?.navigationController?.pushViewController(SecuritySettingsRouter.module(), animated: true)
    }

    func showManageCoins() {
        viewController?.navigationController?.pushViewController(ManageWalletsRouter.module(presentationMode: .pushed), animated: true)
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
        let module = LanguageSettingsRouter.module { MainRouter.module(selectedTab: .settings) }
        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func showAbout() {
        viewController?.navigationController?.pushViewController(AboutSettingsRouter.module(), animated: true)
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
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module(selectedTab: .settings))
    }

}

extension MainSettingsRouter {

    static func module() -> UIViewController {
        let router = MainSettingsRouter()
        let interactor = MainSettingsInteractor(
                backupManager: App.shared.backupManager,
                themeManager: App.shared.themeManager,
                systemInfoManager: App.shared.systemInfoManager,
                currencyKit: App.shared.currencyKit,
                appConfigProvider: App.shared.appConfigProvider
        )
        let presenter = MainSettingsPresenter(router: router, interactor: interactor)
        let view = MainSettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
