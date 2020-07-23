import UIKit

class ChartNotificationRouter {
    weak var viewController: UIViewController?
}

extension ChartNotificationRouter: IChartNotificationRouter {

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

}

extension ChartNotificationRouter {

    static func module(coin: Coin) -> UIViewController {
        let router = ChartNotificationRouter()
        let interactor = ChartNotificationInteractor(priceAlertManager: App.shared.priceAlertManager, notificationManager: App.shared.notificationManager, appManager: App.shared.appManager)
        let presenter = ChartNotificationPresenter(router: router, interactor: interactor, coin: coin)
        let viewController = ChartNotificationViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}
