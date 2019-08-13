import RxSwift

class SendBinanceInteractor {
    weak var delegate: ISendBinanceInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let wallet: Wallet
    private let adapter: ISendBinanceAdapter

    init(wallet: Wallet, adapter: ISendBinanceAdapter) {
        self.wallet = wallet
        self.adapter = adapter
    }

}

extension SendBinanceInteractor: ISendBinanceInteractor {

    var coin: Coin {
        return wallet.coin
    }

    var availableBalance: Decimal {
        return adapter.availableBalance
    }

    var availableBinanceBalance: Decimal {
        return adapter.availableBinanceBalance
    }

    func validate(address: String) throws {
        try adapter.validate(address: address)
    }

    var fee: Decimal {
        return adapter.fee
    }

    func send(amount: Decimal, address: String, memo: String?) {
        adapter.sendSingle(amount: amount, address: address, memo: memo)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] in
                    self?.delegate?.didSend()
                }, onError: { [weak self] error in
                    self?.delegate?.didFailToSend(error: error)
                })
                .disposed(by: disposeBag)
    }

}
