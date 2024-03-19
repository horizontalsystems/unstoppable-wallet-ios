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

        transactionConverter = EvmTransactionConverter(source: wallet.transactionSource, baseToken: baseToken, coinManager: coinManager, evmKitWrapper: evmKitWrapper, evmLabelManager: evmLabelManager)

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
            self?.balanceData(balance: $0) ?? BalanceData(available: 0)
        }
    }
}

extension Eip20Adapter: ISendEthereumAdapter {
    func transactionData(amount: BigUInt, address: EvmKit.Address) -> TransactionData {
        eip20Kit.transferTransactionData(to: address, value: amount)
    }
}

extension Eip20Adapter: IErc20Adapter {
    var pendingTransactions: [TransactionRecord] {
        eip20Kit.pendingTransactions().map { transactionConverter.transactionRecord(fromTransaction: $0) }
    }

    func allowanceSingle(spenderAddress: EvmKit.Address, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Decimal> {
        let decimals = decimals

        return eip20Kit.allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: defaultBlockParameter)
            .map { allowanceString in
                if let significand = Decimal(string: allowanceString) {
                    return Decimal(sign: .plus, exponent: -decimals, significand: significand)
                }

                return 0
            }
    }

    func allowance(spenderAddress: EvmKit.Address, defaultBlockParameter: DefaultBlockParameter) async throws -> Decimal {
        let allowanceString = try await eip20Kit.allowance(spenderAddress: spenderAddress, defaultBlockParameter: defaultBlockParameter)

        guard let significand = Decimal(string: allowanceString) else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -decimals, significand: significand)
    }
}

extension Eip20Adapter: IApproveDataProvider {
    func approveTransactionData(spenderAddress: EvmKit.Address, amount: BigUInt) -> TransactionData {
        eip20Kit.approveTransactionData(spenderAddress: spenderAddress, amount: amount)
    }
}
