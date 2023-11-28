import Combine
import Foundation
import MarketKit

class WalletTokenService {
    private let element: WalletModule.Element

    init(element: WalletModule.Element) {
        self.element = element
    }
}

extension WalletTokenService {
    var coinName: String {
        element.name
    }

    var badge: String? {
        element.wallet?.badge
    }
}
