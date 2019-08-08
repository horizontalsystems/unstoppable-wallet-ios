import RxSwift

class SendBitcoinInteractor {
    weak var delegate: ISendBitcoinInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let wallet: Wallet
    private let adapter: ISendBitcoinAdapter

    init(wallet: Wallet, adapter: ISendBitcoinAdapter) {
        self.wallet = wallet
        self.adapter = adapter
    }

}

extension SendBitcoinInteractor: ISendBitcoinInteractor {

    var coin: Coin {
        return wallet.coin
    }

    func fetchAvailableBalance(feeRate: Int, address: String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let balance = self.adapter.availableBalance(feeRate: feeRate, address: address)

            DispatchQueue.main.async {
                self.delegate?.didFetch(availableBalance: balance)
            }
        }
    }

    func validate(address: String) throws {
        try adapter.validate(address: address)
    }

    func fetchFee(amount: Decimal, feeRate: Int, address: String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fee = self.adapter.fee(amount: amount, feeRate: feeRate, address: address)

            DispatchQueue.main.async {
                self.delegate?.didFetch(fee: fee)
            }
        }
    }

    func send(amount: Decimal, address: String, feeRate: Int) {
        adapter.sendSingle(amount: amount, address: address, feeRate: feeRate)
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
