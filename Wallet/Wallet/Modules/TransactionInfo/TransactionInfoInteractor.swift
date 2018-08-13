import Foundation
import GrouviExtensions
import RxSwift

class TransactionInfoInteractor {
    let disposeBag = DisposeBag()

    weak var delegate: ITransactionInfoInteractorDelegate?

    private let storage: IStorage
    private let coinManager: CoinManager

    private let transaction: TransactionRecordViewItem//stab

    init(transaction: TransactionRecordViewItem, storage: IStorage, coinManager: CoinManager) {
        self.transaction = transaction
        self.storage = storage
        self.coinManager = coinManager
    }

}
extension TransactionInfoInteractor: ITransactionInfoInteractor {

    func getTransactionInfo(coinCode: String, txHash: String) {
        Observable<TransactionRecordViewItem?>.create { [weak self] observer in
            observer.onNext(self?.transaction)
            observer.onCompleted()
            return Disposables.create()
        }.subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] transaction in
            if let transaction = transaction {
                self?.delegate?.didGetTransactionInfo(txRecordViewItem: transaction)
            }
        })
        //stab
//        delegate?.didGetTransactionInfo(txRecordViewItem: <#T##TransactionRecordViewItem##Bank.TransactionRecordViewItem#>)
    }

    func onCopyFromAddress() {
        UIPasteboard.general.setValue(transaction.from, forPasteboardType: "public.plain-text")
        let alert = UIAlertController(title: nil, message: "copied", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.show()
    }

}
