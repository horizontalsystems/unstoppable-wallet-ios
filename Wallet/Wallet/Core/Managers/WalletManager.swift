class WalletManager {
    private(set) var wallets: [Wallet] = []

    private let wordsManager: IWordsManager
    private let coinManager: ICoinManager
    private let adapterFactory: IAdapterFactory

    init(wordsManager: IWordsManager, coinManager: ICoinManager, adapterFactory: IAdapterFactory) {
        self.wordsManager = wordsManager
        self.coinManager = coinManager
        self.adapterFactory = adapterFactory

        initWallets()
    }

}

extension WalletManager: IWalletManager {

    func initWallets() {
        if let words = wordsManager.words {
            for coin in coinManager.enabledCoins {
                if let adapter = adapterFactory.adapter(forCoin: coin, words: words) {
                    wallets.append(Wallet(coin: coin, adapter: adapter))
                    adapter.start()
                }
            }
        }
    }

    func refreshWallets() {
        for wallet in wallets {
            wallet.adapter.refresh()
        }
    }

    func clearWallets() {
        for wallet in wallets {
            wallet.adapter.clear()
        }
    }

}

extension WalletManager: ICoinManagerDelegate {

    func didEnable(coin: Coin) {
    }

    func didDisable(coin: Coin) {
    }

}
