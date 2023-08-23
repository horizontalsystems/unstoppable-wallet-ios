import Foundation
import MarketKit
import Combine

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