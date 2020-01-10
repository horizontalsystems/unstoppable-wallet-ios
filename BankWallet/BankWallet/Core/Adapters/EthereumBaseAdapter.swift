import EthereumKit
import RxSwift

class EthereumBaseAdapter {
    let ethereumKit: EthereumKit.Kit

    let decimal: Int

    init(ethereumKit: EthereumKit.Kit, decimal: Int) {
        self.ethereumKit = ethereumKit
        self.decimal = decimal
    }

    func balanceDecimal(balanceString: String?, decimal: Int) -> Decimal {
        if let balanceString = balanceString, let significand = Decimal(string: balanceString) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }
        return 0
    }

    func sendSingle(to address: String, value: String, gasPrice: Int, gasLimit: Int) -> Single<Void> {
        fatalError("Method should be overridden in child class")
    }

    func estimateGasLimit(to address: String, value: Decimal, gasPrice: Int?) -> Single<Int> {
        fatalError("Method should be overridden in child class")
    }

    func createSendError(from error: Error) -> Error {
        error.convertedError
    }

}

// IAdapter
extension EthereumBaseAdapter: IAdapter {

    func start() {
        // started via EthereumKitManager
    }

    func stop() {
        // stopped via EthereumKitManager
    }

    func refresh() {
        // refreshed via EthereumKitManager
    }

    var debugInfo: String {
        ethereumKit.debugInfo
    }

}

extension EthereumBaseAdapter {
    //todo: Make ethereumKit errors public!
    enum AddressConversion: Error {
        case invalidAddress
    }
}

// ISendEthereumAdapter
extension EthereumBaseAdapter {

    func sendSingle(amount: Decimal, address: String, gasPrice: Int, gasLimit: Int) -> Single<Void> {
        let poweredDecimal = amount * pow(10, decimal)
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let roundedDecimal = NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue

        let amountString = String(describing: roundedDecimal)

        return sendSingle(to: address, value: amountString, gasPrice: gasPrice, gasLimit: gasLimit)
    }

    func validate(address: String) throws {
        //todo: remove when make errors public
        do {
            try ethereumKit.validate(address: address)
        } catch {
            throw AddressConversion.invalidAddress
        }
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
        ethereumKit.receiveAddress
    }

}
