import UIKit
import MarketKit

class NotificationSettingsRouter {
    weak var viewController: UIViewController?
}

extension NotificationSettingsRouter: INotificationSettingsRouter {

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func openSettings(coinType: CoinType, coinTitle: String, mode: NotificationSettingPresentMode) {
        guard let chartNotificationViewController = ChartNotificationRouter.module(coinType: coinType, coinTitle: coinTitle, mode: mode) else {
            return
        }
        viewController?.present(chartNotificationViewController, animated: true)
    }

}

extension NotificationSettingsRouter {

    static func module() -> UIViewController {
        let router = NotificationSettingsRouter()
        let interactor = NotificationSettingsInteractor(priceAlertManager: App.shared.priceAlertManager, notificationManager: App.shared.notificationManager, appManager: App.shared.appManager, coinManager: App.shared.coinManagerNew, localStorage: App.shared.localStorage)
        let factory = NotificationSettingsViewItemFactory()
        let presenter = NotificationSettingsPresenter(router: router, interactor: interactor, factory: factory)
        let view = NotificationSettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
