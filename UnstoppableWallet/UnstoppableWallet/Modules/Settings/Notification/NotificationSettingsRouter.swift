import UIKit

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

    func openSettings(alert: PriceAlert, mode: NotificationSettingPresentMode) {
        viewController?.present(ChartNotificationRouter.module(coin: alert.coin, mode: mode), animated: true)
    }

}

extension NotificationSettingsRouter {

    static func module() -> UIViewController {
        let router = NotificationSettingsRouter()
        let interactor = NotificationSettingsInteractor(priceAlertManager: App.shared.priceAlertManager, notificationManager: App.shared.notificationManager, appManager: App.shared.appManager, localStorage: App.shared.localStorage)
        let presenter = NotificationSettingsPresenter(router: router, interactor: interactor)
        let view = NotificationSettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
