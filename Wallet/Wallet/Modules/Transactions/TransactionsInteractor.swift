import Foundation
import RxSwift

class TransactionsInteractor {

    weak var delegate: ITransactionsInteractorDelegate?

    private let disposeBag = DisposeBag()
    private let databaseManager: IDatabaseManager
    private let coinManager: CoinManager

    private var latestBlockHeights = [String: Int]()
    private var transactionRecords = [TransactionRecord]()

    init(databaseManager: IDatabaseManager, coinManager: CoinManager) {
        self.databaseManager = databaseManager
        self.coinManager = coinManager

        latestBlockHeights["BTC"] = 1500000
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func retrieveTransactionRecords() {
        databaseManager.getTransactionRecords()
                .subscribe(onNext: { [weak self] databaseChangeSet in
                    self?.transactionRecords = databaseChangeSet.array
                    self?.refresh(changeSet: databaseChangeSet.changeSet)
                })
                .disposed(by: disposeBag)

        databaseManager.getBlockchainInfos()
                .subscribe(onNext: { [weak self] databaseChangeSet in
                    for blockchainInfo in databaseChangeSet.array {
                        self?.latestBlockHeights[blockchainInfo.coinCode] = blockchainInfo.latestBlockHeight
                    }
                    self?.refresh()
                })
                .disposed(by: disposeBag)
    }

    private func refresh(changeSet: CollectionChangeSet? = nil) {
        let items = transactionRecords.compactMap { transaction -> TransactionRecordViewItem? in
            guard let latestBlocHeight = self.latestBlockHeights[transaction.coinCode] else {
                return nil
            }

            guard let coin = self.coinManager.getCoin(byCode: transaction.coinCode) else {
                return nil
            }

            let confirmations = transaction.blockHeight == 0 ? 0 : max(0, latestBlocHeight - transaction.blockHeight + 1)

            return TransactionRecordViewItem(
                    transactionHash: transaction.transactionHash,
                    amount: CoinValue(coin: coin, value: Double(transaction.amount) / 100000000),
                    fee: CoinValue(coin: coin, value: Double(transaction.fee) / 100000000),
                    from: transaction.from,
                    to: transaction.to,
                    incoming: transaction.incoming,
                    blockHeight: transaction.blockHeight,
                    date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                    status: confirmations > 0 ? .success : .pending,
                    confirmations: confirmations
            )
        }

        delegate?.didRetrieve(items: items, changeSet: changeSet)
    }

}
