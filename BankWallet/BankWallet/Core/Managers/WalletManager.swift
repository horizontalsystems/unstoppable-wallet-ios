import RxSwift

class WalletManager {
    private let disposeBag = DisposeBag()
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

    private let walletFactory: IWalletFactory
    private let wordsManager: IWordsManager
    private let coinManager: ICoinManager

    private(set) var wallets: [Wallet] = []
    let walletsSubject = PublishSubject<[Wallet]>()

    private var subject = OptionalSubject<[Wallet]>()

    init(walletFactory: IWalletFactory, wordsManager: IWordsManager, coinManager: ICoinManager) {
        self.walletFactory = walletFactory
        self.wordsManager = wordsManager
        self.coinManager = coinManager

        Observable.combineLatest(coinManager.coinsObservable, wordsManager.authDataObservable)
                { coins, authData -> ([Coin], AuthData) in
                    return (coins, authData)
                }
                .subscribeOn(scheduler)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] coins, authData in
                    self?.handle(coins: coins, authData: authData)
                })
                .disposed(by: disposeBag)
    }

    private func handle(coins: [Coin], authData: AuthData) {
        let wallets = coins.compactMap { coin in
            subject.value?.first(where: { $0.coinCode == coin.code }) ?? walletFactory.wallet(forCoin: coin, authData: authData)
        }

        subject.onNext(wallets)
    }

}

extension WalletManager: IWalletManager {

    var walletsObservable: Observable<[Wallet]> {
        return subject.asObservable()
    }

}
