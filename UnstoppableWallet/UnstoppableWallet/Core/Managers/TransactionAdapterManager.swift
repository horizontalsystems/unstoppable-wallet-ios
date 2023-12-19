import Foundation
import RxRelay
import RxSwift

class TransactionAdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterManager: AdapterManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let adapterFactory: AdapterFactory

    private let adaptersReadyRelay = PublishRelay<Void>()

    private let queue = DispatchQueue(label: "\(AppConfig.label).transactions_adapter_manager", qos: .userInitiated)
    private var _adapterMap = [TransactionSource: ITransactionsAdapter]()

    init(adapterManager: AdapterManager, evmBlockchainManager: EvmBlockchainManager, adapterFactory: AdapterFactory) {
        self.adapterManager = adapterManager
        self.evmBlockchainManager = evmBlockchainManager
        self.adapterFactory = adapterFactory

        adapterManager.adapterDataReadyObservable
            .observeOn(SerialDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] adapterData in
                self?.initAdapters(adapterMap: adapterData.adapterMap)
            })
            .disposed(by: disposeBag)
    }

    private func initAdapters(adapterMap: [Wallet: IAdapter]) {
        var newAdapterMap = [TransactionSource: ITransactionsAdapter]()

        for (wallet, adapter) in adapterMap {
            let source = wallet.transactionSource

            guard newAdapterMap[source] == nil else {
                continue
            }

            let transactionsAdapter: ITransactionsAdapter?

            if evmBlockchainManager.allBlockchains.contains(where: { $0.type == source.blockchainType }) {
                transactionsAdapter = adapterFactory.evmTransactionsAdapter(transactionSource: source)
            } else if source.blockchainType == .tron {
                transactionsAdapter = adapterFactory.tronTransactionsAdapter(transactionSource: source)
            } else {
                transactionsAdapter = adapter as? ITransactionsAdapter
            }

            if let transactionsAdapter {
                newAdapterMap[source] = transactionsAdapter
            }
        }

        queue.async {
            self._adapterMap = newAdapterMap
            self.adaptersReadyRelay.accept(())
        }
    }
}

extension TransactionAdapterManager {
    var adapterMap: [TransactionSource: ITransactionsAdapter] {
        queue.sync { _adapterMap }
    }

    var adaptersReadyObservable: Observable<Void> {
        adaptersReadyRelay.asObservable()
    }

    func adapter(for source: TransactionSource) -> ITransactionsAdapter? {
        queue.sync { _adapterMap[source] }
    }
}
