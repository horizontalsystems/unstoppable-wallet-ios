import RxSwift

class TokenSyncer: ITokenSyncer {
    private let disposeBag = DisposeBag()

    private let tokenNetworkManager: ITokenNetworkManager
    private let storage: ICoinStorage
    private let async: Bool

    init(tokenNetworkManager: ITokenNetworkManager, storage: ICoinStorage, async: Bool = true) {
        self.tokenNetworkManager = tokenNetworkManager
        self.storage = storage
        self.async = async
    }

    func sync() {
        var observable = Observable.zip(tokenNetworkManager.getTokens(), storage.enabledCoinsObservable().take(1), storage.allCoinsObservable().take(1))

        if async {
            observable = observable.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).observeOn(MainScheduler.instance)
        }

        observable.subscribe(onNext: { [weak self] (newCoins, enabledCoins, allCoins) in
                    self?.update(newCoins: newCoins, enabledCoins: enabledCoins, allCoins: allCoins)
                })
                .disposed(by: disposeBag)
    }

    private func update(newCoins: [Coin], enabledCoins: [Coin], allCoins: [Coin]) {
        let inserted = newCoins.filter { !allCoins.contains($0) }
        let deleted = allCoins.filter { !(enabledCoins.contains($0) || newCoins.contains($0)) }

        guard !inserted.isEmpty || !deleted.isEmpty else {
            return
        }

        storage.update(inserted: inserted, deleted: deleted)
    }

}
