class WalletFactory {
    private let adapterFactory: IAdapterFactory

    init(adapterFactory: IAdapterFactory) {
        self.adapterFactory = adapterFactory
    }

}

extension WalletFactory: IWalletFactory {

    func wallet(forCoin coin: Coin, authData: AuthData) -> Wallet? {
        guard let adapter = adapterFactory.adapter(forCoinType: coin.type, authData: authData) else {
            return nil
        }

        adapter.start()

        return Wallet(title: coin.title, coinCode: coin.code, adapter: adapter)
    }

}
