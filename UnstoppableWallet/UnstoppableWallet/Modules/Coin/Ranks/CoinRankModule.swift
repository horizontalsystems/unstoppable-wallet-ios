import SwiftUI
import ThemeKit
import UIKit

enum CoinRankModule {
    static func viewController(type: RankType) -> UIViewController {
        let service = CoinRankService(
            type: type,
            marketKit: App.shared.marketKit,
            currencyManager: App.shared.currencyManager
        )

        let viewModel = CoinRankViewModel(service: service)
        let viewController = CoinRankViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

    static func newView(type: RankType) -> UIViewController {
        let isPresented = Binding<Bool>(get: { true }, set: { _ in })
        return RankView(isPresented: isPresented, type: type).toViewController()
    }
}

extension CoinRankModule {
    enum RankType {
        case cexVolume
        case dexVolume
        case dexLiquidity
        case address
        case txCount
        case holders
        case fee
        case revenue
    }
}
