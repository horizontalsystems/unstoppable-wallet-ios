import RxSwift

class SendEthereumInteractor {
    private let adapter: ISendEthereumAdapter

    init(adapter: ISendEthereumAdapter) {
        self.adapter = adapter
    }

}

extension SendEthereumInteractor: ISendEthereumInteractor {

    func availableBalance(gasPrice: Int) -> Decimal {
        adapter.availableBalance(gasPrice: gasPrice)
    }

    var ethereumBalance: Decimal {
        adapter.ethereumBalance
    }

    var minimumRequiredBalance: Decimal {
        adapter.minimumRequiredBalance
    }

    func validate(address: String) throws {
        try adapter.validate(address: address)
    }

    func fee(gasPrice: Int) -> Decimal {
        adapter.fee(gasPrice: gasPrice)
    }

    func sendSingle(amount: Decimal, address: String, gasPrice: Int) -> Single<Void> {
        adapter.sendSingle(amount: amount, address: address, gasPrice: gasPrice)
    }

}
