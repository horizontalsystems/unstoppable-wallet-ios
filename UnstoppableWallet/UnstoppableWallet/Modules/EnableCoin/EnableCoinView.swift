import UIKit

class EnableCoinView {
    private let coinTokensView: CoinTokensView
    private let restoreSettingsView: RestoreSettingsView
    private let coinSettingsView: CoinSettingsView

    var onOpenController: ((UIViewController) -> ())? {
        didSet {
            coinTokensView.onOpenController = onOpenController
            restoreSettingsView.onOpenController = onOpenController
            coinSettingsView.onOpenController = onOpenController
        }
    }

    init(coinTokensView: CoinTokensView, restoreSettingsView: RestoreSettingsView, coinSettingsView: CoinSettingsView) {
        self.coinTokensView = coinTokensView
        self.restoreSettingsView = restoreSettingsView
        self.coinSettingsView = coinSettingsView
    }

}
