import RxSwift

class AddErc20TokenInteractor {
    weak var delegate: IAddErc20TokenInteractorDelegate?

    private let pasteboardManager: IPasteboardManager
    private var disposeBag = DisposeBag()

    init(pasteboardManager: IPasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

    private func coinSingle(address: String) -> Single<Coin> {
        Single.create { observer in
            let coin = Coin(
                    id: "ERM",
                    title: "Ermat",
                    code: "ERM",
                    decimal: 18,
                    type: CoinType(erc20Address: address)
            )

            Thread.sleep(forTimeInterval: 1)

            observer(SingleEvent.success(coin))

            return Disposables.create()
        }
    }

}

extension AddErc20TokenInteractor: IAddErc20TokenInteractor {

    var valueFromPasteboard: String? {
        pasteboardManager.value
    }

    func validate(address: String) throws {
        // todo: validate via EthereumKit
    }

    func existingCoin(address: String) -> Coin? {
        // todo: check address in hardcoded coins list and already saved coins
        nil
    }

    func fetchCoin(address: String) {
        // todo: replace single with Infura coin info single
        coinSingle(address: address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onSuccess: { [weak self] coin in
                            self?.delegate?.didFetch(coin: coin)
                        },
                        onError: { [weak self] error in
                            self?.delegate?.didFailToFetchCoin(error: error)
                        }
                )
                .disposed(by: disposeBag)
    }

    func abortFetchingCoin() {
        disposeBag = DisposeBag()
    }

    func save(coin: Coin) {
        // todo: save coin to database
    }

}
