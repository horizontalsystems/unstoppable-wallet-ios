import SwiftUI

enum CoinReportsModule {
    static func viewController(coinUid: String) -> CoinReportsViewController {
        let service = CoinReportsService(coinUid: coinUid, marketKit: App.shared.marketKit)
        let viewModel = CoinReportsViewModel(service: service)
        return CoinReportsViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }
}

struct CoinReportsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let coinUid: String

    func makeUIViewController(context _: Context) -> UIViewController {
        CoinReportsModule.viewController(coinUid: coinUid)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
