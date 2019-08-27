import RxSwift

class SendEthereumInteractor {
    private let adapter: ISendEthereumAdapter

    init(adapter: ISendEthereumAdapter) {
        self.adapter = adapter
    }

}

extension SendEthereumInteractor: ISendEthereumInteractor {

    func availableBalance(gasPrice: Int) -> Decimal {
        return adapter.availableBalance(gasPrice: gasPrice)
    }

    var ethereumBalance: Decimal {
        return adapter.ethereumBalance
    }

    func validate(address: String) throws {
        try adapter.validate(address: address)
    }

    func fee(gasPrice: Int) -> Decimal {
        return adapter.fee(gasPrice: gasPrice)
    }

    func sendSingle(amount: Decimal, address: String, gasPrice: Int) -> Single<Void> {
        return adapter.sendSingle(amount: amount, address: address, gasPrice: gasPrice)
    }

}
