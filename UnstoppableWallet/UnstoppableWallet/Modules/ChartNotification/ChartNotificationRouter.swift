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

    static func module(coin: Coin, mode: NotificationSettingPresentMode) -> UIViewController {
        let factory: IChartNotificationViewModelFactory

        switch mode {
        case .all: factory = ChartNotificationViewModelFactory()
        case .price: factory = PriceChangeAlertSettingViewModelFactory()
        case .trend: factory = PriceTrendAlertSettingViewModelFactory()
        }

        let router = ChartNotificationRouter()
        let interactor = ChartNotificationInteractor(priceAlertManager: App.shared.priceAlertManager, notificationManager: App.shared.notificationManager, appManager: App.shared.appManager)
        let presenter = ChartNotificationPresenter(router: router, interactor: interactor, factory: factory, coin: coin, presentMode: mode)
        let viewController = ChartNotificationViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}
