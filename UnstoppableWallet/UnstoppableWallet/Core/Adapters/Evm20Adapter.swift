import EthereumKit
import Erc20Kit
import RxSwift
import BigInt
import HsToolKit
import MarketKit

class Evm20Adapter: BaseEvmAdapter {
    private static let approveConfirmationsThreshold: Int? = nil
    let evm20Kit: Erc20Kit.Kit
    private let contractAddress: EthereumKit.Address
    private let transactionConverter: EvmTransactionConverter

    init(evmKitWrapper: EvmKitWrapper, contractAddress: String, wallet: Wallet, baseCoin: PlatformCoin, coinManager: CoinManager) throws {
        let address = try EthereumKit.Address(hex: contractAddress)
        evm20Kit = try Erc20Kit.Kit.instance(ethereumKit: evmKitWrapper.evmKit, contractAddress: address)
        self.contractAddress = address

        transactionConverter = EvmTransactionConverter(source: wallet.transactionSource, baseCoin: baseCoin, coinManager: coinManager, evmKitWrapper: evmKitWrapper)

        super.init(evmKitWrapper: evmKitWrapper, decimals: wallet.decimals)
    }

}

// IAdapter

extension Evm20Adapter: IAdapter {

    func start() {
        evm20Kit.start()
    }

    func stop() {
        evm20Kit.stop()
    }

    func refresh() {
    }

}

extension Evm20Adapter: IBalanceAdapter {

    var balanceState: AdapterState {
        convertToAdapterState(evmSyncState: evm20Kit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        evm20Kit.syncStateObservable.map { [unowned self] in self.convertToAdapterState(evmSyncState: $0) }
    }

    var balanceData: BalanceData {
        balanceData(balance: evm20Kit.balance)
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        evm20Kit.balanceObservable.map { [unowned self] in self.balanceData(balance: $0) }
    }

}

extension Evm20Adapter: ISendEthereumAdapter {

    func transactionData(amount: BigUInt, address: EthereumKit.Address) -> TransactionData {
        evm20Kit.transferTransactionData(to: address, value: amount)
    }

}

extension Evm20Adapter: IErc20Adapter {

    var pendingTransactions: [TransactionRecord] {
        evm20Kit.pendingTransactions().map { transactionConverter.transactionRecord(fromTransaction: $0) }
    }

    func allowanceSingle(spenderAddress: EthereumKit.Address, defaultBlockParameter: DefaultBlockParameter = .latest) -> Single<Decimal> {
        evm20Kit.allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: defaultBlockParameter)
                .map { [unowned self] allowanceString in
                    if let significand = Decimal(string: allowanceString) {
                        return Decimal(sign: .plus, exponent: -decimals, significand: significand)
                    }

                    return 0
                }
    }

}
