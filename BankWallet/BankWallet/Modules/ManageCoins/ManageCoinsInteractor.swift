import RxSwift

class ManageCoinsInteractor {
    weak var delegate: IManageCoinsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let appConfigProvider: IAppConfigProvider
    private let storage: IEnabledWalletStorage

    init(appConfigProvider: IAppConfigProvider, storage: IEnabledWalletStorage) {
        self.appConfigProvider = appConfigProvider
        self.storage = storage
    }

}

extension ManageCoinsInteractor: IManageCoinsInteractor {

    func loadCoins() {
        let allCoins = appConfigProvider.coins
        var enabledCoins = [Coin]()

        storage.enabledWalletsObservable
                .subscribe(onNext: {
                    enabledCoins = $0.compactMap { enabledCoin in
                        allCoins.first { coin in
                            enabledCoin.coinCode == coin.code
                        }
                    }
                })
                .disposed(by: disposeBag)

        delegate?.didLoad(allCoins: allCoins, enabledCoins: enabledCoins)
    }

    func save(enabledCoins coins: [Coin]) {
        var enabledCoins = [EnabledWallet]()

//        for (order, coin) in coins.enumerated() {
//            enabledCoins.append(EnabledCoin(coinCode: coin.code, order: order))
//        }
//
//        storage.save(enabledWallets: enabledCoins)
        delegate?.didSaveCoins()
    }

}
