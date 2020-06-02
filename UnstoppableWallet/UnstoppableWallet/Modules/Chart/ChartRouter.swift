import UIKit
import ThemeKit
import LanguageKit
import Chart
import SafariServices

class ChartRouter {
    weak var viewController: UIViewController?
}

extension ChartRouter {

    static func module(coinCode: String, coinTitle: String) -> UIViewController {
        let router = ChartRouter()
        let chartRateFactory = ChartRateFactory(timelineHelper: TimelineHelper(), indicatorFactory: IndicatorFactory(), currentLocale: LanguageManager.shared.currentLocale)
        let interactor = ChartInteractor(rateManager: App.shared.rateManager, chartTypeStorage: App.shared.localStorage, currentDateProvider: CurrentDateProvider())
        let presenter = ChartPresenter(interactor: interactor, factory: chartRateFactory, coinCode: coinCode, coinTitle: coinTitle, currency: App.shared.currencyKit.baseCurrency)
        let viewController = ChartViewController(delegate: presenter, configuration: ChartConfiguration.fullChart)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
