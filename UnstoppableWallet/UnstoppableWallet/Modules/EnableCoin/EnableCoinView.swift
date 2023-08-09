import UIKit

class EnableCoinView {
    private let coinTokensView: CoinTokensView
    private let restoreSettingsView: RestoreSettingsView

    var onOpenController: ((UIViewController) -> ())? {
        didSet {
            coinTokensView.onOpenController = onOpenController
            restoreSettingsView.onOpenController = onOpenController
        }
    }

    init(coinTokensView: CoinTokensView, restoreSettingsView: RestoreSettingsView) {
        self.coinTokensView = coinTokensView
        self.restoreSettingsView = restoreSettingsView
    }

}
