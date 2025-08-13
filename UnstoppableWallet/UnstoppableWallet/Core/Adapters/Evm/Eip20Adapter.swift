import BigInt
import Eip20Kit
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import RxSwift

class Eip20Adapter: BaseEvmAdapter {
    private static let approveConfirmationsThreshold: Int? = nil
    let eip20Kit: Eip20Kit.Kit
    private let contractAddress: EvmKit.Address
    private let transactionConverter: EvmTransactionConverter

    init(evmKitWrapper: EvmKitWrapper, contractAddress: String, wallet: Wallet, baseToken: Token, coinManager: CoinManager, evmLabelManager: EvmLabelManager) throws {
        let address = try EvmKit.Address(hex: contractAddress)
        eip20Kit = try Eip20Kit.Kit.instance(evmKit: evmKitWrapper.evmKit, contractAddress: address)
        self.contractAddress = address

        transactionConverter = EvmTransactionConverter(
            source: wallet.transactionSource, baseToken: baseToken, coinManager: coinManager, blockchainType: evmKitWrapper.blockchainType,
            userAddress: evmKitWrapper.evmKit.address, evmLabelManager: evmLabelManager
        )

        super.init(evmKitWrapper: evmKitWrapper, decimals: wallet.decimals)
    }
}

// IAdapter

extension Eip20Adapter: IAdapter {
    func start() {
        eip20Kit.start()
    }

    func stop() {
        eip20Kit.stop()
    }

    func refresh() {}
}

extension Eip20Adapter: IBalanceAdapter {
    var balanceState: AdapterState {
        convertToAdapterState(evmSyncState: eip20Kit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        eip20Kit.syncStateObservable.map { [weak self] in
            self?.convertToAdapterState(evmSyncState: $0) ?? .syncing(progress: nil, lastBlockDate: nil)
        }
    }

    var balanceData: BalanceData {
        balanceData(balance: eip20Kit.balance)
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        eip20Kit.balanceObservable.map { [weak self] in
            self?.balanceData(balance: $0) ?? BalanceData(balance: 0)
        }
    }
}

extension Eip20Adapter: ISendEthereumAdapter {
    func transactionData(amount: BigUInt, address: EvmKit.Address) -> TransactionData {
        eip20Kit.transferTransactionData(to: address, value: amount)
    }
}

extension Eip20Adapter: IAllowanceAdapter {
    var pendingTransactions: [TransactionRecord] {
        eip20Kit.pendingTransactions().map { transactionConverter.transactionRecord(fromTransaction: $0) }
    }

    func allowance(spenderAddress: Address, defaultBlockParameter: BlockParameter) async throws -> Decimal {
        let address = try EvmKit.Address(hex: spenderAddress.raw)
        let allowanceString = try await eip20Kit.allowance(spenderAddress: address, defaultBlockParameter: .init(defaultBlockParameter))
        
        guard let significand = Decimal(string: allowanceString) else {
            return 0
        }
        
        return Decimal(sign: .plus, exponent: -decimals, significand: significand)
    }
}

extension Eip20Adapter: IApproveDataProvider {
    func approveTransactionData(spenderAddress: Address, amount: BigUInt) throws -> TransactionData {
        let address = try EvmKit.Address(hex: spenderAddress.raw)
        return eip20Kit.approveTransactionData(spenderAddress: address, amount: amount)
    }
}

extension DefaultBlockParameter {
    init(_ blockParameter: BlockParameter) {
        switch blockParameter {
        case .pending: self = .pending
        case .latest: self = .latest
        case .earliest: self = .earliest
        case let .blockNumber(value): self = .blockNumber(value: value)
        }
    }
}
