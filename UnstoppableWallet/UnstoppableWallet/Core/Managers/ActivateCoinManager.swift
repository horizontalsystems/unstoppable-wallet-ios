import CoinKit

class ActivateCoinManager {
    private let coinKit: CoinKit.Kit
    private let walletManager: IWalletManager
    private let accountManager: IAccountManager

    init(coinKit: CoinKit.Kit, walletManager: IWalletManager, accountManager: IAccountManager) {
        self.coinKit = coinKit
        self.walletManager = walletManager
        self.accountManager = accountManager
    }

    func activate(coinType: CoinType) {
        guard let coin = coinKit.coin(type: coinType) else {
            // coin type is not supported
            return
        }

        guard !walletManager.activeWallets.contains(where: { $0.coin == coin }) else {
            // wallet already exists
            return
        }

        guard let account = accountManager.activeAccount else {
            // active account does not exist
            return
        }

        let wallet = Wallet(coin: coin, account: account)
        walletManager.save(wallets: [wallet])
    }

}
