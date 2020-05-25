import UIKit

class NotificationSettingsRouter {
    weak var viewController: UIViewController?
}

extension NotificationSettingsRouter: INotificationSettingsRouter {

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

}

extension NotificationSettingsRouter {

    static func module() -> UIViewController {
        let router = NotificationSettingsRouter()
        let interactor = NotificationSettingsInteractor(priceAlertManager: App.shared.priceAlertManager, notificationManager: App.shared.notificationManager, appManager: App.shared.appManager)
        let presenter = NotificationSettingsPresenter(router: router, interactor: interactor)
        let view = NotificationSettingsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
