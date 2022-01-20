import RxSwift

class SendZcashInteractor {
    private let adapter: ISendZcashAdapter

    init(adapter: ISendZcashAdapter) {
        self.adapter = adapter
    }

}

extension SendZcashInteractor: ISendZcashInteractor {

    var availableBalance: Decimal {
        adapter.availableBalance
    }

    var fee: Decimal {
        adapter.fee
    }

    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void> {
        adapter.sendSingle(amount: amount, address: address, memo: memo)
    }

}
