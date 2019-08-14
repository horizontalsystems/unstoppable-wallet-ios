import EthereumKit
import RxSwift

class EthereumBaseAdapter {
    let ethereumKit: EthereumKit

    let decimal: Int

    init(ethereumKit: EthereumKit, decimal: Int) {
        self.ethereumKit = ethereumKit
        self.decimal = decimal
    }

    func balanceDecimal(balanceString: String?, decimal: Int) -> Decimal {
        if let balanceString = balanceString, let significand = Decimal(string: balanceString) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }
        return 0
    }

    func sendSingle(to address: String, value: String, gasPrice: Int) -> Single<Void> {
        fatalError("Method should be overridden in child class")
    }

    func createSendError(from error: Error) -> Error {
        if let error = error as? EthereumKit.NetworkError, case .noConnection = error {
            return SendTransactionError.connection
        } else {
            return SendTransactionError.unknown
        }
    }

}

// IAdapter
extension EthereumBaseAdapter {

    func start() {
        // started via EthereumKitManager
    }

    func stop() {
        // stopped via EthereumKitManager
    }

    func refresh() {
        // refreshed via EthereumKitManager
    }

    func sendSingle(amount: Decimal, address: String, gasPrice: Int) -> Single<Void> {
        let poweredDecimal = amount * pow(10, decimal)
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let roundedDecimal = NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue

        let amountString = String(describing: roundedDecimal)

        return sendSingle(to: address, value: amountString, gasPrice: gasPrice)
    }

    func validate(address: String) throws {
        //todo: remove when make errors public
        do {
            try ethereumKit.validate(address: address)
        } catch {
            throw AddressConversion.invalidAddress
        }
    }

    var debugInfo: String {
        return ethereumKit.debugInfo
    }

}

extension EthereumBaseAdapter {
    //todo: Make ethereumKit errors public!
    enum AddressConversion: Error {
        case invalidAddress
    }
}

// ITransactionsAdapter
extension EthereumBaseAdapter {

    var confirmationsThreshold: Int {
        return 12
    }

    var lastBlockHeight: Int? {
        return ethereumKit.lastBlockHeight
    }

    var lastBlockHeightUpdatedObservable: Observable<Void> {
        return ethereumKit.lastBlockHeightObservable.map { _ in () }
    }

}

extension EthereumBaseAdapter: IDepositAdapter {

    var receiveAddress: String {
        return ethereumKit.receiveAddress
    }

}
