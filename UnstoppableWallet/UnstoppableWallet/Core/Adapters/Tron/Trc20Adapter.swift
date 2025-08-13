import BigInt
import Foundation
import HsToolKit
import MarketKit
import RxSwift
import TronKit

class Trc20Adapter: BaseTronAdapter {
    private let contractAddress: TronKit.Address

    private let transactionConverter: TronTransactionConverter

    init(tronKitWrapper: TronKitWrapper, contractAddress: String, wallet: Wallet, baseToken: Token, coinManager: CoinManager, evmLabelManager: EvmLabelManager) throws {
        self.contractAddress = try TronKit.Address(address: contractAddress)

        transactionConverter = TronTransactionConverter(source: wallet.transactionSource, baseToken: baseToken, coinManager: coinManager, tronKitWrapper: tronKitWrapper, evmLabelManager: evmLabelManager)

        super.init(tronKitWrapper: tronKitWrapper, decimals: wallet.decimals)
    }
}

// IAdapter
extension Trc20Adapter: IAdapter {
    func start() {
        // started via TronKitManager
    }

    func stop() {
        // stopped via TronKitManager
    }

    func refresh() {
        // refreshed via TronKitManager
    }
}

extension Trc20Adapter: IBalanceAdapter {
    var balanceState: AdapterState {
        convertToAdapterState(tronSyncState: tronKit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        tronKit.syncStatePublisher.asObservable().map { [weak self] in
            self?.convertToAdapterState(tronSyncState: $0) ?? .syncing(progress: nil, lastBlockDate: nil)
        }
    }

    var balanceData: BalanceData {
        balanceData(balance: tronKit.trc20Balance(contractAddress: contractAddress))
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        tronKit.trc20BalancePublisher(contractAddress: contractAddress).asObservable().map { [weak self] in
            self?.balanceData(balance: $0) ?? BalanceData(balance: 0)
        }
    }
}

extension Trc20Adapter: ISendTronAdapter {
    func contract(amount: BigUInt, address: TronKit.Address, memo _: String?) -> Contract {
        tronKit.transferTrc20TriggerSmartContract(contractAddress: contractAddress, toAddress: address, amount: amount)
    }
}

extension Trc20Adapter: IAllowanceAdapter {
    var pendingTransactions: [TransactionRecord] {
        tronKit.pendingTransactions().map { transactionConverter.transactionRecord(fromTransaction: $0) }
    }

    func allowance(spenderAddress: Address, defaultBlockParameter: BlockParameter) async throws -> Decimal {
        let spenderAddress = try TronKit.Address(address: spenderAddress.raw)
        let allowanceString = try await tronKit.allowance(contractAddress: contractAddress, spenderAddress: spenderAddress)
        
        guard let significand = Decimal(string: allowanceString) else {
            return 0
        }
        
        return Decimal(sign: .plus, exponent: -decimals, significand: significand)
    }
}
