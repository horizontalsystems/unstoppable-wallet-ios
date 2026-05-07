import Foundation

import MarketKit

class ReceiveSettingsViewModel: ObservableObject {
    let wallets: [Wallet]

    init(wallets: [Wallet]) {
        self.wallets = wallets
    }

    var viewItems: [ViewItem] {
        []
    }

    func item(uid _: String) -> Wallet? {
        nil
    }

    var title: String { fatalError("Must be overridden by subclass") }
    var topDescription: String { fatalError("Must be overridden by subclass") }
    var highlightedBottomDescription: String? { nil }
}

extension ReceiveSettingsViewModel {
    struct ViewItem: Hashable {
        let uid: String
        let title: String
        let subtitle: String
    }
}
