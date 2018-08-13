import UIKit
import WalletKit
import GrouviActionSheet

class TransactionInfoRouter {
}

extension TransactionInfoRouter: ITransactionInfoRouter {
}

extension TransactionInfoRouter {

    static func module(controller: UIViewController?, transaction: TransactionRecordViewItem, coinCode: String, txHash: String) {
        let router = TransactionInfoRouter()
        // transaction is stab
        let interactor = TransactionInfoInteractor(transaction: transaction, storage: RealmStorage.shared, coinManager: CoinManager())
        let presenter = TransactionInfoPresenter(interactor: interactor, router: router, coinCode: coinCode, transactionHash: txHash)
        interactor.delegate = presenter

        let view = TransactionInfoView(controller: controller, delegate: presenter)
        presenter.view = view

        presenter.viewDidLoad()
    }

}
