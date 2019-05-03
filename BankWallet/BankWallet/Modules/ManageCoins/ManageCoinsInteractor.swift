import RxSwift

class ManageCoinsInteractor {
    weak var delegate: IManageCoinsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let coinManager: ICoinManager
    private let storage: ICoinStorage

    init(coinManager: ICoinManager, storage: ICoinStorage) {
        self.coinManager = coinManager
        self.storage = storage
    }

}

extension ManageCoinsInteractor: IManageCoinsInteractor {

    func loadCoins() {
        var enabledCoins = [Coin]()

        storage.enabledCoinsObservable()
                .subscribe(onNext: {
                    enabledCoins = $0
                })
                .disposed(by: disposeBag)

        delegate?.didLoad(allCoins: coinManager.allCoins, enabledCoins: enabledCoins)
    }

    func save(enabledCoins: [Coin]) {
        storage.save(enabledCoins: enabledCoins)
        delegate?.didSaveCoins()
    }

}
