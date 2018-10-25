import UIKit
import GrouviActionSheet

class DepositRouter {
    weak var presentingViewController: UIViewController?
    weak var viewController: ActionSheetController?

    var viewModel: IDepositView?

}

extension DepositRouter: IDepositRouter {

    func showView(with addresses: [AddressItem]) {
        let depositAlertModel = DepositAlertModel(addresses: addresses, onCopy: { [weak self] index in
            self?.viewModel?.onCopy(index: index)
        }, onShare: { [weak self] index in
            self?.viewModel?.onShare(index: index)
        })

        let viewController = ActionSheetController(withModel: depositAlertModel, actionStyle: .sheet(showDismiss: false))
        viewController.backgroundColor = .cryptoBarsColor
        viewController.onDismiss = { [weak self] state in
            self?.viewModel = nil

        }

        self.viewController = viewController
        viewController.show(fromController: presentingViewController)
    }

    func share(address: String) {
//        viewController?.dismiss()
//        viewController?.onDismiss = { [weak self] state in
//            self?.viewModel = nil

            let activityViewController = UIActivityViewController(activityItems: [address], applicationActivities: [])
//            UIApplication.shared.keyWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
            viewController?.present(activityViewController, animated: true, completion: nil)
//        }
    }

}

extension DepositRouter {

    static func module(presentingViewController: UIViewController?, coin: Coin?) {
        let wallets = App.shared.walletManager.wallets.filter { coin == nil || coin == $0.coin }

        let router = DepositRouter()
        router.presentingViewController = presentingViewController
        let interactor = DepositInteractor(wallets: wallets)
        let presenter = DepositPresenter(interactor: interactor, router: router)
        interactor.delegate = presenter

        let viewModel = DepositViewModel(viewDelegate: presenter)
        presenter.view = viewModel
        router.viewModel = viewModel

        presenter.viewDidLoad()
    }

}
