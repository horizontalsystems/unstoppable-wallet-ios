import RxSwift

class SendDashInteractor {
    weak var delegate: ISendDashInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let adapter: ISendDashAdapter

    init(adapter: ISendDashAdapter) {
        self.adapter = adapter
    }

}

extension SendDashInteractor: ISendDashInteractor {

    func fetchAvailableBalance(address: String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let balance = self.adapter.availableBalance(address: address)

            DispatchQueue.main.async {
                self.delegate?.didFetch(availableBalance: balance)
            }
        }
    }

    func validate(address: String) throws {
        try adapter.validate(address: address)
    }

    func fetchFee(amount: Decimal, address: String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fee = self.adapter.fee(amount: amount, address: address)

            DispatchQueue.main.async {
                self.delegate?.didFetch(fee: fee)
            }
        }
    }

    func send(amount: Decimal, address: String) {
        adapter.sendSingle(amount: amount, address: address)
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
