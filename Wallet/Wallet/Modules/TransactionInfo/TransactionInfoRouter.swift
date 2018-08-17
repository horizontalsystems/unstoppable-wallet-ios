import UIKit
import GrouviActionSheet

class TransactionInfoRouter {
    var controller: UIViewController?
}

extension TransactionInfoRouter: ITransactionInfoRouter {

    func showFullInfo(transaction: TransactionRecordViewItem) {
        let infoController = FullTransactionInfoController(transaction: transaction)
        let navigation = UINavigationController(rootViewController: infoController)
        navigation.navigationBar.barStyle = .blackTranslucent
        navigation.navigationBar.tintColor = .cryptoYellow
        controller?.present(navigation, animated: true)
    }

    func onCreate(controller: UIViewController) {
        self.controller = controller
    }
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
