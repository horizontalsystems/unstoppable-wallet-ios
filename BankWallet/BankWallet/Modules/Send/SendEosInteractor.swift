import RxSwift

class SendEosInteractor {
    weak var delegate: ISendEosInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let adapter: ISendEosAdapter

    init(adapter: ISendEosAdapter) {
        self.adapter = adapter
    }

}

extension SendEosInteractor: ISendEosInteractor {

    var availableBalance: Decimal {
        return adapter.availableBalance
    }

    func validate(account: String) throws {
        try adapter.validate(account: account)
    }

    func send(amount: Decimal, account: String, memo: String?) {
        adapter.sendSingle(amount: amount, account: account, memo: memo)
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
