import MarketKit
import SwiftUI
import ThemeKit
import UIKit

struct CoinAnalyticsModule {
    static func view(fullCoin: FullCoin) -> some View {
        CoinAnalyticsView(fullCoin: fullCoin)
    }

    static func viewController(fullCoin: FullCoin) -> CoinAnalyticsViewController {
        let service = CoinAnalyticsService(
            fullCoin: fullCoin,
            marketKit: App.shared.marketKit,
            currencyKit: App.shared.currencyKit,
            subscriptionManager: App.shared.subscriptionManager
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
            "coin_analytics.overall_score.\(rawValue)".localized
        }

        var image: UIImage? {
            UIImage(named: "rating_\(rawValue)_24")
        }

        var color: UIColor {
            switch self {
            case .excellent: return .themeGreenD
            case .good: return .themeYellowD
            case .fair: return UIColor(hex: 0xFF7A00)
            case .poor: return .themeRedD
            }
        }
    }
}

struct CoinAnalyticsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let fullCoin: FullCoin

    func makeUIViewController(context _: Context) -> UIViewController {
        CoinAnalyticsModule.viewController(fullCoin: fullCoin)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
