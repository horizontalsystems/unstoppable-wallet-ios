import RxSwift

class ManageCoinsInteractor {
    weak var delegate: IManageCoinsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let coinManager: ICoinManager
    private let storage: ICoinStorage
    private let async: Bool

    init(coinManager: ICoinManager, storage: ICoinStorage, async: Bool) {
        self.coinManager = coinManager
        self.storage = storage
        self.async = async
    }

}

extension ManageCoinsInteractor: IManageCoinsInteractor {

    func loadCoins() {
        delegate?.didLoad(allCoins: coinManager.allCoins)

        var enabledCoinsObservable = storage.enabledCoinsObservable()

        if async {
            enabledCoinsObservable = enabledCoinsObservable
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
        }

        enabledCoinsObservable.subscribe(onNext: { [weak self] enabledCoins in
            self?.delegate?.didLoad(enabledCoins: enabledCoins)
        }).disposed(by: disposeBag)
    }

    func save(enabledCoins: [Coin]) {
        storage.save(enabledCoins: enabledCoins)
        delegate?.didSaveCoins()
    }

}
