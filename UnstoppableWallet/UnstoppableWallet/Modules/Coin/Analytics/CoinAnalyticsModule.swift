import MarketKit
import SwiftUI
import ThemeKit
import UIKit

struct CoinAnalyticsModule {
    static func view(fullCoin: FullCoin, apiTag: String) -> some View {
        CoinAnalyticsView(fullCoin: fullCoin, apiTag: apiTag)
    }

    static func viewController(fullCoin: FullCoin, apiTag: String) -> CoinAnalyticsViewController {
        let service = CoinAnalyticsService(
            fullCoin: fullCoin,
            marketKit: App.shared.marketKit,
            currencyManager: App.shared.currencyManager,
            subscriptionManager: App.shared.subscriptionManager,
            apiTag: apiTag
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
    let apiTag: String

    func makeUIViewController(context _: Context) -> UIViewController {
        CoinAnalyticsModule.viewController(fullCoin: fullCoin, apiTag: apiTag)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
