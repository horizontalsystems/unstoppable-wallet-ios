import UIKit
import MarketKit

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

    static func module(coinType: CoinType, coinTitle: String, mode: NotificationSettingPresentMode) -> UIViewController? {
        let factory: IChartNotificationViewModelFactory

        switch mode {
        case .all: factory = ChartNotificationViewModelFactory()
        case .price: factory = PriceChangeAlertSettingViewModelFactory()
        case .trend: factory = PriceTrendAlertSettingViewModelFactory()
        }

        let router = ChartNotificationRouter()
        let interactor = ChartNotificationInteractor(priceAlertManager: App.shared.priceAlertManager, notificationManager: App.shared.notificationManager, appManager: App.shared.appManager)
        guard let presenter = ChartNotificationPresenter(router: router, interactor: interactor, factory: factory, coinType: coinType, coinTitle: coinTitle, presentMode: mode) else {
            return nil
        }

        let viewController = ChartNotificationViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}
