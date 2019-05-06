import RxSwift

class ManageCoinsInteractor {
    weak var delegate: IManageCoinsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let coinManager: ICoinManager
    private let storage: IEnabledCoinStorage

    init(coinManager: ICoinManager, storage: IEnabledCoinStorage) {
        self.coinManager = coinManager
        self.storage = storage
    }

}

extension ManageCoinsInteractor: IManageCoinsInteractor {

    func loadCoins() {
        let allCoins = coinManager.allCoins
        var enabledCoins = [Coin]()

        storage.enabledCoinsObservable
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
        var enabledCoins = [EnabledCoin]()

        for (order, coin) in coins.enumerated() {
            enabledCoins.append(EnabledCoin(coinCode: coin.code, order: order))
        }

        storage.save(enabledCoins: enabledCoins)
        delegate?.didSaveCoins()
    }

}
