import UIKit
import ThemeKit
import MarketKit

struct CoinAnalyticsModule {

    static func viewController(fullCoin: FullCoin) -> CoinAnalyticsViewController {
        let service = CoinAnalyticsService(
                fullCoin: fullCoin,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                subscriptionManager: App.shared.subscriptionManager,
                accountManager: App.shared.accountManager,
                appConfigProvider: App.shared.appConfigProvider
        )
        let technicalIndicatorService = TechnicalIndicatorService(
                coinUid: fullCoin.coin.uid,
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )
        let coinIndicatorViewItemFactory = CoinIndicatorViewItemFactory()
        let viewModel = CoinAnalyticsViewModel(
                service: service,
                technicalIndicatorService: technicalIndicatorService,
                coinIndicatorViewItemFactory: coinIndicatorViewItemFactory
        )

        return CoinAnalyticsViewController(viewModel: viewModel)
    }

}

extension CoinAnalyticsModule {

    enum Rating: String, CaseIterable {
        case excellent
        case good
        case fair
        case poor

        var title: String {
            "coin_analytics.rating_scale.\(rawValue)".localized
        }

        var percents: String {
            switch self {
            case .excellent: return "25%"
            case .good: return "25%-50%"
            case .fair: return "50%-75%"
            case .poor: return "75%-100%"
            }
        }

        var image: UIImage? {
            UIImage(named: "rating_\(rawValue)_24")
        }

        var color: UIColor {
            switch self {
            case .excellent: return .themeGreenD
            case .good: return .themeYellowD
            case .fair: return UIColor(hex: 0xff7a00)
            case .poor: return .themeRedD
            }
        }
    }

}
