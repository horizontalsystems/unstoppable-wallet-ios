import Combine
import Foundation
import MarketKit

class WalletTokenService {
    private let wallet: Wallet

    init(wallet: Wallet) {
        self.wallet = wallet
    }
}

extension WalletTokenService {
    var coinName: String {
        wallet.coin.code
    }

    var badge: String? {
        wallet.badge
    }
}
