import MarketKit
import SwiftUI
import ThemeKit
import UIKit

enum CoinAnalyticsModule {
    static func viewController(fullCoin: FullCoin) -> CoinAnalyticsViewController {
        let service = CoinAnalyticsService(
            fullCoin: fullCoin,
            marketKit: App.shared.marketKit,
            currencyManager: App.shared.currencyManager,
            subscriptionManager: App.shared.subscriptionManager
        )
        let technicalIndicatorService = TechnicalIndicatorService(
            coinUid: fullCoin.coin.uid,
            currencyManager: App.shared.currencyManager,
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
    enum Rating: String, CaseIterable, Identifiable {
        case excellent
        case good
        case fair
        case poor

        var id: Self {
            self
        }

        var title: String {
            "coin_analytics.overall_score.\(rawValue)".localized
        }

        var image: UIImage? {
            UIImage(named: "rating_\(rawValue)_24")
        }

        var imageNew: Image? {
            Image("rating_\(rawValue)_24")
        }

        var color: UIColor {
            switch self {
            case .excellent: return .themeGreenD
            case .good: return .themeYellowD
            case .fair: return UIColor(hex: 0xFF7A00)
            case .poor: return .themeRedD
            }
        }

        var colorNew: Color {
            switch self {
            case .excellent: return .themeGreen
            case .good: return .themeYellow
            case .fair: return Color(hex: 0xFF7A00)
            case .poor: return .themeRed
            }
        }
    }
}
