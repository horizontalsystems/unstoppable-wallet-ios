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

    private func customPlatformCoin(coinType: CoinType) -> PlatformCoin? {
        walletManager.activeWallets.first(where: { $0.coinType == coinType })?.platformCoin
    }

}

extension CoinManager {

    func platformCoin(coinType: CoinType) throws -> PlatformCoin? {
        try marketKit.platformCoin(coinType: coinType) ?? customPlatformCoin(coinType: coinType)
    }

}
