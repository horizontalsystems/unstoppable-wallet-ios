import Foundation
import GrouviExtensions
import RxSwift

class TransactionInfoInteractor {
    let disposeBag = DisposeBag()

    weak var delegate: ITransactionInfoInteractorDelegate?

    private let transaction: TransactionRecordViewItem

    init(transaction: TransactionRecordViewItem) {
        self.transaction = transaction
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
    }

    func onCopyFromAddress() {
        UIPasteboard.general.setValue(transaction.from ?? "", forPasteboardType: "public.plain-text")
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
