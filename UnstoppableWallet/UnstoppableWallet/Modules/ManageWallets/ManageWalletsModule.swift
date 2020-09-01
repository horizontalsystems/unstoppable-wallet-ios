import UIKit
import ThemeKit

struct ManageWalletsModule {

    static func instance() -> UIViewController {
        let service = ManageWalletsService(
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                accountManager: App.shared.accountManager,
                derivationSettingsManager: App.shared.derivationSettingsManager
        )
        let viewModel = ManageWalletsViewModel(service: service)
        let viewController = ManageWalletsViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

    struct State {
        let featuredItems: [Item]
        let items: [Item]

        static var empty: State {
            State(featuredItems: [], items: [])
        }
    }

    class Item {
        let coin: Coin
        var state: ItemState

        init(coin: Coin, state: ItemState) {
            self.coin = coin
            self.state = state
        }
    }

    enum ItemState: CustomStringConvertible {
        case noAccount
        case hasAccount(hasWallet: Bool)
    }

    struct ViewState {
        let featuredViewItems: [CoinToggleViewItem]
        let viewItems: [CoinToggleViewItem]

        static var empty: ViewState {
            ViewState(featuredViewItems: [], viewItems: [])
        }
    }

}

class CoinToggleViewItem {
    let coin: Coin
    var state: CoinToggleViewItemState

    init(coin: Coin, state: CoinToggleViewItemState) {
        self.coin = coin
        self.state = state
    }
}

enum CoinToggleViewItemState: CustomStringConvertible {
    case toggleHidden
    case toggleVisible(enabled: Bool)

    var description: String {
        switch self {
        case .toggleHidden: return "hidden"
        case .toggleVisible(let enabled): return "visible_\(enabled)"
        }
    }

}
