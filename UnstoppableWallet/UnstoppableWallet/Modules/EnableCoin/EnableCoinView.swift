import UIKit

class EnableCoinView {
    private let coinTokensView: CoinTokensView
    private let coinSettingsView: CoinSettingsView

    var onOpenController: ((UIViewController) -> ())? {
        didSet {
            coinTokensView.onOpenController = onOpenController
            coinSettingsView.onOpenController = onOpenController
        }
    }

    init(coinTokensView: CoinTokensView, coinSettingsView: CoinSettingsView) {
        self.coinTokensView = coinTokensView
        self.coinSettingsView = coinSettingsView
    }

}
