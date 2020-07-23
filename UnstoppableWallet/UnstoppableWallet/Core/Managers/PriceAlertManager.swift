import RxSwift

class PriceAlertManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let remoteAlertManager: IRemoteAlertManager
    private let storage: IPriceAlertStorage

    private let updateSubject = PublishSubject<[PriceAlert]>()

    init(walletManager: IWalletManager, storage: IPriceAlertStorage, remoteAlertManager: IRemoteAlertManager) {
        self.walletManager = walletManager
        self.storage = storage
        self.remoteAlertManager = remoteAlertManager

        walletManager.walletsUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] wallets in
                    self?.onUpdate(wallets: wallets)
                })
                .disposed(by: disposeBag)
    }

    private func onUpdate(wallets: [Wallet]) {
        let coinCodes = wallets.map { $0.coin.code }

        storage.deleteExcluding(coinCodes: coinCodes)
    }

}

extension PriceAlertManager: IPriceAlertManager {

    var updateObservable: Observable<[PriceAlert]> {
        updateSubject.asObservable()
    }

    var priceAlerts: [PriceAlert] {
        let alerts = storage.priceAlerts

        return walletManager.wallets.map { wallet in
            let coin = wallet.coin

            if let alert = alerts.first(where: { $0.coin == coin }) {
                return alert
            }

            return PriceAlert(coin: coin, state: .off)
        }
    }

    func priceAlert(coin: Coin) -> PriceAlert {
        storage.priceAlert(coin: coin) ?? PriceAlert(coin: coin, state: .off)
    }

    func save(priceAlerts: [PriceAlert]) -> Observable<[()]> {
        var toBeSaved = [PriceAlert]()
        var toBeDeleted = [PriceAlert]()

        for priceAlert in priceAlerts {
            if priceAlert.state == .off {
                toBeDeleted.append(priceAlert)
            } else {
                toBeSaved.append(priceAlert)
            }
        }

        var singles = [Single<()>]()

        if !toBeSaved.isEmpty {
            singles.append(
                    remoteAlertManager.handle(newAlerts: toBeSaved)
                            .do(onSuccess: { [weak self] in
                                self?.storage.save(priceAlerts: toBeSaved)
                            })
            )
        }

        if !toBeDeleted.isEmpty {
            singles.append(
                    remoteAlertManager.handle(deletedAlerts: toBeDeleted)
                            .do(onSuccess: { [weak self] in
                                self?.storage.delete(priceAlerts: toBeDeleted)
                            })
            )
        }

        return Single.zip(singles).asObservable().do(onCompleted: { [weak self] in
            self?.updateSubject.onNext(priceAlerts)
        })
    }

}
