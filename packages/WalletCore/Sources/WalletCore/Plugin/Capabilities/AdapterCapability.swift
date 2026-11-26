import Combine
import MarketKit

/// Supplies the balance and transactions adapters of the plugin's blockchains.
///
/// - `adapter(wallet:)` and `transactionsAdapter(source:walletAdapter:)` are called on background queues
///   (`AdapterManager`'s and `TransactionAdapterManager`'s init queues) and must be thread-safe.
/// - A `nil` result is final for that wallet or source: the caller does not fall back to its legacy switch.
/// - `adaptersInvalidated` emits the blockchain type whose adapters must be recreated, and may emit on any thread.
public protocol AdapterCapability: BlockchainPlugin {
    func adapter(wallet: Wallet) -> IAdapter?
    func transactionsAdapter(source: TransactionSource, walletAdapter: IAdapter) -> ITransactionsAdapter?
    var adaptersInvalidated: AnyPublisher<BlockchainType, Never> { get }
}
