import EthereumKit
import RxSwift
import BigInt
import HsToolKit

class BaseEvmAdapter {
    static let confirmationsThreshold = 12
    let evmKit: EthereumKit.Kit

    let decimal: Int

    init(evmKit: EthereumKit.Kit, decimal: Int) {
        self.evmKit = evmKit
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

    func convertToAdapterState(evmSyncState: EthereumKit.SyncState) -> AdapterState {
        switch evmSyncState {
            case .synced: return .synced
            case .notSynced(let error): return .notSynced(error: error.convertedError)
            case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

}

// ISendEthereumAdapter
extension BaseEvmAdapter {

    func sendSingle(amount: Decimal, address: String, gasPrice: Int, gasLimit: Int, logger: Logger) -> Single<Void> {
        sendSingle(to: address, value: amount, gasPrice: gasPrice, gasLimit: gasLimit, logger: logger)
    }

}

// ITransactionsAdapter
extension BaseEvmAdapter {

    var lastBlockInfo: LastBlockInfo? {
        evmKit.lastBlockHeight.map { LastBlockInfo(height: $0, timestamp: nil) }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        evmKit.lastBlockHeightObservable.map { _ in () }
    }

}

extension BaseEvmAdapter: IDepositAdapter {

    var receiveAddress: String {
        evmKit.receiveAddress.hex
    }

}
