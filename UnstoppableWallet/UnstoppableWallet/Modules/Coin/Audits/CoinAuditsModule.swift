import MarketKit
import SwiftUI
import UIKit

enum CoinAuditsModule {
    static func viewController(audits: [Analytics.Audit]) -> UIViewController {
        let viewModel = CoinAuditsViewModel(items: audits)
        let urlManager = UrlManager(inApp: true)
        return CoinAuditsViewController(viewModel: viewModel, urlManager: urlManager)
    }
}

struct CoinAuditsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let audits: [Analytics.Audit]

    func makeUIViewController(context _: Context) -> UIViewController {
        CoinAuditsModule.viewController(audits: audits)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
