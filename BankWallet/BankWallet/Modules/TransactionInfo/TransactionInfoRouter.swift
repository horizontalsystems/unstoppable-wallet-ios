import UIKit
import GrouviActionSheet

class TransactionInfoRouter {
    var controller: UIViewController?
}

extension TransactionInfoRouter: ITransactionInfoRouter {

    func showFullInfo(transaction: TransactionViewItem) {
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

    static func module(controller: UIViewController?, transaction: TransactionViewItem) {
        let router = TransactionInfoRouter()
        let interactor = TransactionInfoInteractor(transaction: transaction)
        let presenter = TransactionInfoPresenter(interactor: interactor, router: router)
        interactor.delegate = presenter

        let view = TransactionInfoView(controller: controller, delegate: presenter)
        presenter.view = view

        presenter.viewDidLoad()
    }

}
