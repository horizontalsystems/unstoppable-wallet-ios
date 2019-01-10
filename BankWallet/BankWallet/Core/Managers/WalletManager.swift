import RxSwift

class WalletManager {
    private let walletFactory: IWalletFactory
    private let authManager: IAuthManager
    private let coinManager: ICoinManager

    private(set) var wallets: [Wallet] = []
    let walletsUpdatedSignal = Signal()

    init(walletFactory: IWalletFactory, authManager: IAuthManager, coinManager: ICoinManager) {
        self.walletFactory = walletFactory
        self.authManager = authManager
        self.coinManager = coinManager

        initWallets()
    }

}

extension WalletManager: IWalletManager {

    func initWallets() {
        guard let authData = authManager.authData else {
            return
        }

        wallets = coinManager.coins.compactMap { coin in
            wallets.first(where: { $0.coinCode == coin.code }) ?? walletFactory.wallet(forCoin: coin, authData: authData)
        }

        walletsUpdatedSignal.notify()
    }

    func clearWallets() {
        for wallet in wallets {
            wallet.adapter.clear()
        }

        wallets = []
        walletsUpdatedSignal.notify()
    }

}
