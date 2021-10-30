import UIKit

class EnableCoinView {
    private let coinPlatformsView: CoinPlatformsView
    private let restoreSettingsView: RestoreSettingsView
    private let coinSettingsView: CoinSettingsView

    var onOpenController: ((UIViewController) -> ())? {
        didSet {
            coinPlatformsView.onOpenController = onOpenController
            restoreSettingsView.onOpenController = onOpenController
            coinSettingsView.onOpenController = onOpenController
        }
    }

    init(coinPlatformsView: CoinPlatformsView, restoreSettingsView: RestoreSettingsView, coinSettingsView: CoinSettingsView) {
        self.coinPlatformsView = coinPlatformsView
        self.restoreSettingsView = restoreSettingsView
        self.coinSettingsView = coinSettingsView
    }

}
