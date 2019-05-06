import RxSwift

class CoinManager {
    private let appConfigProvider: IAppConfigProvider
    private let storage: IEnabledCoinStorage

    private let disposeBag = DisposeBag()

    var coins = [Coin]() {
        didSet {
            coinsUpdatedSignal.notify()
        }
    }

    let coinsUpdatedSignal = Signal()

    init(appConfigProvider: IAppConfigProvider, storage: IEnabledCoinStorage) {
        self.appConfigProvider = appConfigProvider
        self.storage = storage

        storage.enabledCoinsObservable
                .subscribe(onNext: { [weak self] enabledCoins in
                    self?.handle(enabledCoins: enabledCoins)
                })
                .disposed(by: disposeBag)
    }

    private func handle(enabledCoins: [EnabledCoin]) {
        coins = enabledCoins.compactMap { enabledCoin in
            return appConfigProvider.coins.first { coin in
                enabledCoin.coinCode == coin.code
            }
        }
    }

}

extension CoinManager: ICoinManager {

    var allCoins: [Coin] { return appConfigProvider.coins }

    func enableDefaultCoins() {
        var enabledCoins = [EnabledCoin]()

        for (order, coinCode) in appConfigProvider.defaultCoinCodes.enumerated() {
            enabledCoins.append(EnabledCoin(coinCode: coinCode, order: order))
        }

        storage.save(enabledCoins: enabledCoins)
    }

    func clear() {
        coins = []
        storage.clearEnabledCoins()
    }

}
