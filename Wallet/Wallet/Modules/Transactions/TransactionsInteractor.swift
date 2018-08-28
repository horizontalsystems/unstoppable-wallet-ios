import Foundation
import RxSwift

class TransactionsInteractor {

    weak var delegate: ITransactionsInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let adapterManager: AdapterManager

    private var latestBlockHeights = [String: Int]()
    private var transactionRecords = [TransactionRecord]()

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func retrieveFilters() {
        let filters = adapterManager.adapters.map { adapter in
            TransactionFilter(adapterId: adapter.id, coinName: adapter.coin.name)
        }

        delegate?.didRetrieve(filters: filters)
    }

    func retrieveTransactionItems(adapterId: String?) {
        var items = [TransactionRecordViewItem]()

        for adapter in adapterManager.adapters {
            let latestBlockHeight = adapter.latestBlockHeight

            for record in adapter.transactionRecords {
                let confirmations = record.blockHeight.map { latestBlockHeight - $0 + 1 } ?? 0

                let item = TransactionRecordViewItem(
                        transactionHash: record.transactionHash,
                        amount: CoinValue(coin: adapter.coin, value: record.amount),
                        fee: CoinValue(coin: adapter.coin, value: record.fee),
                        from: record.from.first,
                        to: record.to.first,
                        incoming: record.amount > 0,
                        blockHeight: record.blockHeight,
                        date: record.timestamp.map { Date(timeIntervalSince1970: Double($0)) },
                        status: confirmations > 0 ? .success : .pending,
                        confirmations: confirmations
                )

                items.append(item)
            }
        }

        delegate?.didRetrieve(items: items)
    }

}
