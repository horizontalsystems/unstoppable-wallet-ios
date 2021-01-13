import EthereumKit
import RxSwift
import BigInt
import HsToolKit

class EthereumBaseAdapter {
    static let confirmationsThreshold = 12
    let ethereumKit: EthereumKit.Kit

    let decimal: Int

    init(ethereumKit: EthereumKit.Kit, decimal: Int) {
        self.ethereumKit = ethereumKit
        self.decimal = decimal
    }

    func validate(address: String) throws {
        _ = try EthereumKit.Address(hex: address)
    }

    func balanceDecimal(kitBalance: BigUInt?, decimal: Int) -> Decimal {
        guard let kitBalance = kitBalance else {
            return 0
        }

        guard let significand = Decimal(string: kitBalance.description) else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -decimal, significand: significand)
    }

    func sendSingle(to address: String, value: Decimal, gasPrice: Int, gasLimit: Int, logger: Logger) -> Single<Void> {
        fatalError("Method should be overridden in child class")
    }

    func createSendError(from error: Error) -> Error {
        error.convertedError
    }

    func convertToAdapterState(ethereumSyncState: EthereumKit.SyncState) -> AdapterState {
        switch ethereumSyncState {
            case .synced: return .synced
            case .notSynced(let error): return .notSynced(error: error.convertedError)
            case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

}

// ISendEthereumAdapter
extension EthereumBaseAdapter {

    func sendSingle(amount: Decimal, address: String, gasPrice: Int, gasLimit: Int, logger: Logger) -> Single<Void> {
        sendSingle(to: address, value: amount, gasPrice: gasPrice, gasLimit: gasLimit, logger: logger)
    }

}

// ITransactionsAdapter
extension EthereumBaseAdapter {

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
