import RxSwift

class SendZCashInteractor {
    private let adapter: ISendZCashAdapter

    init(adapter: ISendZCashAdapter) {
        self.adapter = adapter
    }

}

extension SendZCashInteractor: ISendZCashInteractor {

    var availableBalance: Decimal {
        adapter.availableBalance
    }

    func validate(address: String) throws {
        try adapter.validate(address: address)
    }

    var fee: Decimal {
        adapter.fee
    }

    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void> {
        adapter.sendSingle(amount: amount, address: address, memo: memo)
    }

}
