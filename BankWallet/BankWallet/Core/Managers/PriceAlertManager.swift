import RxSwift

class PriceAlertManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let storage: IPriceAlertStorage

    private let priceAlertCountSubject = PublishSubject<Int>()

    init(walletManager: IWalletManager, storage: IPriceAlertStorage) {
        self.walletManager = walletManager
        self.storage = storage

        walletManager.walletsUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateWallets()
                })
                .disposed(by: disposeBag)
    }

    private func onUpdateWallets() {
        let coinCodes = walletManager.wallets.map { $0.coin.code }

        storage.deleteExcluding(coinCodes: coinCodes)
        priceAlertCountSubject.onNext(storage.priceAlertCount)
    }

}

extension PriceAlertManager: IPriceAlertManager {

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

    var priceAlertCount: Int {
        return storage.priceAlertCount
    }

    var priceAlertCountObservable: Observable<Int> {
        return priceAlertCountSubject.asObservable()
    }

    func save(priceAlert: PriceAlert) {
        if priceAlert.state == .off {
            storage.delete(priceAlert: priceAlert)
        } else {
            storage.save(priceAlert: priceAlert)
        }

        priceAlertCountSubject.onNext(storage.priceAlertCount)
    }

}
