import UIKit
import ThemeKit
import RxSwift

class WalletConnectV1MainRequestView {
    private let disposeBag = DisposeBag()
    private let viewModel: WalletConnectV1MainRequestViewModel
    weak var sourceViewController: UIViewController?

    init(viewModel: WalletConnectV1MainRequestViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.openRequestSignal) { [weak self] in self?.open(request: $0) }
    }

    private func open(request: WalletConnectRequest) {
        var viewController: UIViewController?

        switch request {
        case let request as WalletConnectSendEthereumTransactionRequest:
            viewController = WalletConnectSendEthereumTransactionRequestModule.viewController(signService: viewModel.service, requestId: request.id)
        case let request as WalletConnectSignMessageRequest:
            viewController = WalletConnectSignMessageRequestModule.viewController(signService: viewModel.service, requestId: request.id)
        default: ()
        }

        if let viewController = viewController {
            sourceViewController?.present(ThemeNavigationController(rootViewController: viewController), animated: true)
        }
    }

}

extension WalletConnectV1MainRequestView: IWalletConnectMainRequestView {

}