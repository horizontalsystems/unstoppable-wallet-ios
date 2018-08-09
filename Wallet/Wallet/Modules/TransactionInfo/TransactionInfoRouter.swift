import UIKit
import WalletKit
import GrouviActionSheet

class TransactionInfoRouter {
    weak var viewController: UIViewController?
}

//extension SendRouter: ISendRouter {
//
//    func startScan(result: @escaping ((String) -> ())) {
//        let scanController = ScanQRController()
//        scanController.onCodeParse = result
//        viewController?.present(scanController, animated: true)
//    }
//
//}

extension TransactionInfoRouter {

    static func module(transaction: TransactionRecordViewItem, coinCode: String, txHash: String) -> ActionSheetController {
        let router = TransactionInfoRouter()
//        let interactor = SendInteractor(storage: RealmStorage.shared, coin: coin)
//        let presenter = SendPresenter(interactor: interactor, router: router, coinCode: coin.code)
//        interactor.delegate = presenter

        let sendAlertModel = TransactionInfoAlertModel(transaction: transaction)

        let viewController = ActionSheetController(withModel: sendAlertModel, actionStyle: .sheet(showDismiss: false))
        router.viewController = viewController

        return viewController
    }

}
