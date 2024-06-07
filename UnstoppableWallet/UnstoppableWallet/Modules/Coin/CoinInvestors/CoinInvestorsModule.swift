import SwiftUI
import UIKit

enum CoinInvestorsModule {
    static func viewController(coinUid: String) -> UIViewController {
        let service = CoinInvestorsService(coinUid: coinUid, marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager)
        let viewModel = CoinInvestorsViewModel(service: service)
        return CoinInvestorsViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }
}

struct CoinInvestorsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let coinUid: String

    func makeUIViewController(context _: Context) -> UIViewController {
        CoinInvestorsModule.viewController(coinUid: coinUid)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
