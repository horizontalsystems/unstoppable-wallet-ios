import RxSwift

class SendErc20Interactor {
    weak var delegate: ISendErc20InteractorDelegate?

    private let disposeBag = DisposeBag()

    private let wallet: Wallet
    private let adapter: ISendErc20Adapter

    init(wallet: Wallet, adapter: ISendErc20Adapter) {
        self.wallet = wallet
        self.adapter = adapter
    }

}

extension SendErc20Interactor: ISendErc20Interactor {

    var coin: Coin {
        return wallet.coin
    }

    var availableBalance: Decimal {
        return adapter.availableBalance
    }

    var availableEthereumBalance: Decimal {
        return adapter.availableEthereumBalance
    }

    func validate(address: String) throws {
        try adapter.validate(address: address)
    }

    func fee(gasPrice: Int) -> Decimal {
        return adapter.fee(gasPrice: gasPrice)
    }

    func send(amount: Decimal, address: String, gasPrice: Int) {
        adapter.sendSingle(amount: amount, address: address, gasPrice: gasPrice)
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
