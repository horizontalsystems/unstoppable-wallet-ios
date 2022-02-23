import MarketKit

class ActivateCoinManager {
    private let marketKit: Kit
    private let walletManager: WalletManager
    private let accountManager: IAccountManager

    init(marketKit: Kit, walletManager: WalletManager, accountManager: IAccountManager) {
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.accountManager = accountManager
    }

    private func activate(coinType: CoinType) {
        guard let platformCoin = try? marketKit.platformCoin(coinType: coinType) else {
            // coin type is not supported
            return
        }

        guard !walletManager.activeWallets.contains(where: { $0.platformCoin == platformCoin }) else {
            // wallet already exists
            return
        }

        guard let account = accountManager.activeAccount else {
            // active account does not exist
            return
        }

        let wallet = Wallet(platformCoin: platformCoin, account: account)
        walletManager.save(wallets: [wallet])
    }

}

extension ActivateCoinManager {

    func activateBaseCoin(blockchain: EvmBlockchain) {
        activate(coinType: blockchain.baseCoinType)
    }

    func activateEvm20Coin(address: String, blockchain: EvmBlockchain) {
        activate(coinType: blockchain.evm20CoinType(address: address))
    }

}
