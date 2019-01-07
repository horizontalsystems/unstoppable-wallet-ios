import RxSwift

class WalletManager {
    private let adapterFactory: IAdapterFactory

    private(set) var wallets: [Wallet] = []
    let walletsSubject = PublishSubject<[Wallet]>()

    init(adapterFactory: IAdapterFactory) {
        self.adapterFactory = adapterFactory
    }
}

extension WalletManager: IWalletManager {

    var walletsObservable: Observable<[Wallet]> {
        return Observable.just(wallets)
    }

    func initWallets(authData: AuthData, coins: [Coin]) {
        var newWallets = [Wallet]()

        wallets = coins.compactMap { coin in
            if let wallet = self.wallets.first(where: { $0.coinCode == coin.code }) {
                return wallet
            }

            guard let adapter = adapterFactory.adapter(forCoinType: coin.type, authData: authData) else {
                return nil
            }

            let wallet = Wallet(title: coin.title, coinCode: coin.code, adapter: adapter)
            newWallets.append(wallet)
            return wallet
        }

        walletsSubject.onNext(wallets)

        newWallets.forEach { $0.adapter.start() }
    }

    func clearWallets() {
        for wallet in wallets {
            wallet.adapter.clear()
        }
        wallets = []
    }

}
