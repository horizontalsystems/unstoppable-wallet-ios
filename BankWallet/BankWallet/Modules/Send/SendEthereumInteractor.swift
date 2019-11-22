import RxSwift
import EthereumKit

class SendEthereumInteractor {
    private let adapter: ISendEthereumAdapter

    init(adapter: ISendEthereumAdapter) {
        self.adapter = adapter
    }

}

extension SendEthereumInteractor: ISendEthereumInteractor {

    func availableBalance(gasPrice: Int, gasLimit: Int?) -> Decimal {
        adapter.availableBalance(gasPrice: gasPrice, gasLimit: gasLimit)
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

    func fee(gasPrice: Int, gasLimit: Int) -> Decimal {
        adapter.fee(gasPrice: gasPrice, gasLimit: gasLimit)
    }

    func estimateGasLimit(to address: String, value: Decimal, gasPrice: Int?) -> Single<Int> {
        adapter.estimateGasLimit(to: address, value: value, gasPrice: gasPrice)
    }

    func sendSingle(amount: Decimal, address: String, gasPrice: Int, gasLimit: Int) -> Single<Void> {
        adapter.sendSingle(amount: amount, address: address, gasPrice: gasPrice, gasLimit: gasLimit)
    }

}
