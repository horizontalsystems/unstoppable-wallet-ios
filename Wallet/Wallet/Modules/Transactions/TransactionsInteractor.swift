import Foundation
import RxSwift

class TransactionsInteractor {

    weak var delegate: ITransactionsInteractorDelegate?

    private let disposeBag = DisposeBag()
    private let databaseManager: IDatabaseManager

    init(databaseManager: IDatabaseManager) {
        self.databaseManager = databaseManager
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func retrieveTransactionRecords() {
        databaseManager.getTransactionRecords()
                .subscribe(onNext: { [weak self] databaseChangeSet in
                    let items = databaseChangeSet.array.map { transaction -> TransactionRecordViewItem in
                        let coin: Coin = {
                            switch transaction.coinCode {
                            case "BCH":
                                return BitcoinCash()
                            default:
                                return Bitcoin()
                            }
                        }()

                        return TransactionRecordViewItem(
                                transactionHash: transaction.transactionHash,
                                amount: CoinValue(coin: coin, value: Double(transaction.amount) / 100000000),
                                fee: CoinValue(coin: coin, value: Double(transaction.fee) / 100000000),
                                from: transaction.from,
                                to: transaction.to,
                                incoming: transaction.incoming,
                                blockHeight: transaction.blockHeight,
                                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                                status: nil,
                                confirmations: nil
                        )
                    }

                    self?.delegate?.didRetrieve(items: items, changeSet: databaseChangeSet.changeSet)
                })
                .disposed(by: disposeBag)
    }

}
