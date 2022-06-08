import RxSwift
import RxRelay
import MarketKit

class CoinManager {
    private let marketKit: Kit
    private let walletManager: WalletManager

    init(marketKit: Kit, walletManager: WalletManager) {
        self.marketKit = marketKit
        self.walletManager = walletManager
    }

    private func customToken(query: TokenQuery) -> Token? {
        walletManager.activeWallets.first(where: { $0.token.blockchainType == query.blockchainType && $0.token.type == query.tokenType })?.token
    }

}

extension CoinManager {

    func token(query: TokenQuery) throws -> Token? {
        try marketKit.token(query: query) ?? customToken(query: query)
    }

}
