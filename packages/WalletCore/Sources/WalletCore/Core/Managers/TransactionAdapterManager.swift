import Combine
import Foundation
import MarketKit

public final class TransactionAdapterManager {
    private let adapterFactory: IAdapterFactory

    private let adaptersReadySubject = PassthroughSubject<Void, Never>()

    private let queue = DispatchQueue(label: "WalletCore.transactions_adapter_manager", qos: .userInitiated)
    private var _adapterMap = [TransactionSource: ITransactionsAdapter]()

    public init(adapterFactory: IAdapterFactory) {
        self.adapterFactory = adapterFactory
    }

    private func initAdapters(adapterMap: [Wallet: IAdapter]) {
        queue.async { [weak self] in
            guard let self else { return }

            var newAdapterMap = [TransactionSource: ITransactionsAdapter]()

            for (wallet, adapter) in adapterMap {
                let source = wallet.transactionSource

                guard newAdapterMap[source] == nil else {
                    continue
                }

                if let transactionsAdapter = adapterFactory.transactionsAdapter(transactionSource: source) ?? (adapter as? ITransactionsAdapter) {
                    newAdapterMap[source] = transactionsAdapter
                }
            }

            _adapterMap = newAdapterMap
            adaptersReadySubject.send(())
        }
    }
}

public extension TransactionAdapterManager {
    var adapterMap: [TransactionSource: ITransactionsAdapter] {
        queue.sync { _adapterMap }
    }

    var adaptersReadyPublisher: AnyPublisher<Void, Never> {
        adaptersReadySubject.eraseToAnyPublisher()
    }

    func adapter(for source: TransactionSource) -> ITransactionsAdapter? {
        queue.sync { _adapterMap[source] }
    }

    func handleAdapterDataUpdate(_ adapterMap: [Wallet: IAdapter]) {
        initAdapters(adapterMap: adapterMap)
    }
}
