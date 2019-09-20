import UIKit

class NotificationSettingsRouter {
    weak var viewController: UIViewController?
}

extension NotificationSettingsRouter: INotificationSettingsRouter {
}

extension NotificationSettingsRouter {

    static func module() -> UIViewController {
        let router = NotificationSettingsRouter()
        let interactor = NotificationSettingsInteractor(priceAlertManager: App.shared.priceAlertManager)
        let presenter = NotificationSettingsPresenter(router: router, interactor: interactor)
        let view = NotificationSettingsViewController(delegate: presenter)

        presenter.view = view
        router.viewController = view

        return view
    }

}
