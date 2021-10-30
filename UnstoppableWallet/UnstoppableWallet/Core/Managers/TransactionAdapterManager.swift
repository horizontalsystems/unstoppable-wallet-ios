import RxSwift
import RxRelay

class TransactionAdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterManager: AdapterManager
    private let adapterFactory: AdapterFactory

    private let adaptersReadyRelay = PublishRelay<Void>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.transactions_adapter_manager", qos: .userInitiated)
    private var _adapterMap = [TransactionSource: ITransactionsAdapter]()

    init(adapterManager: AdapterManager, adapterFactory: AdapterFactory) {
        self.adapterManager = adapterManager
        self.adapterFactory = adapterFactory

        adapterManager.adaptersReadyObservable
                .observeOn(SerialDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] adaptersMap in
                    self?.initAdapters(adapterMap: adaptersMap)
                })
                .disposed(by: disposeBag)
    }

    private func evmTransactionAdapter(wallet: Wallet, blockchain: TransactionSource.Blockchain) -> ITransactionsAdapter? {
        switch wallet.coinType {
        case .ethereum, .erc20:
            if case .ethereum = blockchain {
                return adapterFactory.ethereumTransactionsAdapter(transactionSource: wallet.transactionSource)
            }
        case .binanceSmartChain, .bep20:
            if case .binanceSmartChain = blockchain {
                return adapterFactory.bscTransactionsAdapter(transactionSource: wallet.transactionSource)
            }
        default: ()
        }

        return nil
    }

    private func initAdapters(adapterMap: [Wallet: IAdapter]) {
        var newAdapterMap = [TransactionSource: ITransactionsAdapter]()

        for (wallet, adapter) in adapterMap {
            let source = wallet.transactionSource

            guard newAdapterMap[source] == nil else {
                continue
            }

            let transactionsAdapter: ITransactionsAdapter?

            switch source.blockchain {
            case .ethereum: transactionsAdapter = evmTransactionAdapter(wallet: wallet, blockchain: .ethereum)
            case .binanceSmartChain: transactionsAdapter = evmTransactionAdapter(wallet: wallet, blockchain: .binanceSmartChain)
            default: transactionsAdapter = adapter as? ITransactionsAdapter
            }


            if let transactionsAdapter = transactionsAdapter {
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
