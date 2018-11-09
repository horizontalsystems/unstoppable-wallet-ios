import UIKit
import GrouviActionSheet

class TransactionInfoView {
    let controller: UIViewController?
    let delegate: ITransactionInfoViewDelegate

    init(controller: UIViewController?, delegate: ITransactionInfoViewDelegate) {
        self.controller = controller
        self.delegate = delegate
    }

}

extension TransactionInfoView: ITransactionInfoView {

    func showTransactionItem(transactionRecordViewItem: TransactionViewItem) {
        let transactionInfoAlertModel = TransactionInfoAlertModel(transaction: transactionRecordViewItem, onCopyFromAddress: { [weak self] in
            self?.delegate.onCopyFromAddress()
        }, onFullInfo: { [weak self] in
            self?.delegate.onShowFullInfo()
        })
        let viewController = ActionSheetController(withModel: transactionInfoAlertModel, actionStyle: .sheet(showDismiss: false))
        viewController.onDismiss = { [weak self] _ in
            self?.delegate.destroy()
        }
        viewController.show(fromController: controller)
        delegate.onCreate(controller: viewController)
    }

    func expand() {
    }

    func lessen() {
    }

}