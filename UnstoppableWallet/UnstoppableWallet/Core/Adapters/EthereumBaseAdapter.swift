import EthereumKit
import RxSwift

class EthereumBaseAdapter {
    let ethereumKit: EthereumKit.Kit

    let decimal: Int

    init(ethereumKit: EthereumKit.Kit, decimal: Int) {
        self.ethereumKit = ethereumKit
        self.decimal = decimal
    }

    func validate(address: String) throws {
        _ = try Address(hex: address)
    }

    func balanceDecimal(balanceString: String?, decimal: Int) -> Decimal {
        if let balanceString = balanceString, let significand = Decimal(string: balanceString) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }
        return 0
    }

    func sendSingle(to address: String, value: Decimal, gasPrice: Int, gasLimit: Int) -> Single<Void> {
        fatalError("Method should be overridden in child class")
    }

    func createSendError(from error: Error) -> Error {
        error.convertedError
    }

}

// ISendEthereumAdapter
extension EthereumBaseAdapter {

    func sendSingle(amount: Decimal, address: String, gasPrice: Int, gasLimit: Int) -> Single<Void> {
        sendSingle(to: address, value: amount, gasPrice: gasPrice, gasLimit: gasLimit)
    }

}

// ITransactionsAdapter
extension EthereumBaseAdapter {

    var confirmationsThreshold: Int {
        12
    }

    var lastBlockInfo: LastBlockInfo? {
        ethereumKit.lastBlockHeight.map { LastBlockInfo(height: $0, timestamp: nil) }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        ethereumKit.lastBlockHeightObservable.map { _ in () }
    }

}

extension EthereumBaseAdapter: IDepositAdapter {

    var receiveAddress: String {
        ethereumKit.receiveAddress.hex
    }

}
