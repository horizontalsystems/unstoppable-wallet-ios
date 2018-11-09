import Foundation
import GrouviExtensions
import RxSwift

class TransactionInfoInteractor {
    let disposeBag = DisposeBag()

    weak var delegate: ITransactionInfoInteractorDelegate?

    private let transaction: TransactionViewItem

    init(transaction: TransactionViewItem) {
        self.transaction = transaction
    }

}
extension TransactionInfoInteractor: ITransactionInfoInteractor {

    func getTransactionInfo() {
        delegate?.didGetTransactionInfo(txRecordViewItem: transaction)
    }

    func onCopyFromAddress() {
        UIPasteboard.general.setValue(transaction.from ?? "", forPasteboardType: "public.plain-text")
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
