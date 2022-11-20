import UIKit
import RxSwift
import RxCocoa
import ThemeKit
import WalletConnectSign

class WalletConnectV2AppShowView {
    private let disposeBag = DisposeBag()
    private let viewModel: WalletConnectV2AppShowViewModel
    private weak var parentViewController: UIViewController?

    init(viewModel: WalletConnectV2AppShowViewModel, parentViewController: UIViewController?) {
        self.viewModel = viewModel
        self.parentViewController = parentViewController

        subscribe(disposeBag, viewModel.showSessionRequestSignal) { [weak self] request in self?.handle(request: request) }
        subscribe(disposeBag, viewModel.openWalletConnectSignal) { [weak self] in self?.openWalletConnect(mode: $0) }
    }

    private func openWalletConnect(mode: WalletConnectV2AppShowViewModel.WalletConnectOpenMode) {
        switch mode {
        case .noAccount:
            WalletConnectV2AppShowView.showWalletConnectError(error: .noAccount, viewController: parentViewController)
        case .nonSupportedAccountType(let accountTypeDescription):
            WalletConnectV2AppShowView.showWalletConnectError(error: .nonSupportedAccountType(accountTypeDescription: accountTypeDescription), viewController: parentViewController)
        case .pair(let url):
            WalletConnectUriHandler.connect(uri: url) { [weak self] result in
                self?.processWalletConnectPair(result: result)
            }
        case .proposal(let proposal):
            processWalletConnectPair(proposal: proposal)
        }
    }

    private func processWalletConnectPair(proposal: WalletConnectSign.Session.Proposal) {
        DispatchQueue.main.async { [weak self] in
            guard let viewController = WalletConnectMainModule.viewController(proposal: proposal, sourceViewController: self?.parentViewController?.visibleController) else {
                return
            }

            self?.parentViewController?.visibleController.present(viewController, animated: true)
        }
    }

    private func processWalletConnectPair(result: Result<IWalletConnectMainService, Error>) {
        DispatchQueue.main.async { [weak self] in
            switch result {
            case .success(let service):
                guard let viewController = WalletConnectMainModule.viewController(
                        service: service,
                        sourceViewController: self?.parentViewController?.visibleController)
                else {
                    return
                }

                self?.parentViewController?.visibleController.present(viewController, animated: true)
            default: return
            }
        }
    }

    private func handle(request: WalletConnectRequest) {
        guard let viewController = WalletConnectRequestModule.viewController(signService: App.shared.walletConnectV2SessionManager.service, request: request) else {
            return
        }

        parentViewController?.visibleController.present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

}

extension WalletConnectV2AppShowView {

    static func showWalletConnectError(error: WalletConnectOpenError, viewController: UIViewController?) {
        switch error {
        case .noAccount:
            let presentingViewController = InformationModule.simpleInfo(
                    title: "wallet_connect.title".localized,
                    image: UIImage(named: "wallet_connect_24")?.withTintColor(.themeJacob),
                    description: "wallet_connect.no_account.description".localized,
                    buttonTitle: "wallet_connect.no_account.i_understand".localized,
                    onTapButton: InformationModule.afterClose())

            viewController?.present(presentingViewController, animated: true)
        case .nonSupportedAccountType(let accountTypeDescription):
            let presentingViewController = InformationModule.simpleInfo(
                    title: "wallet_connect.title".localized,
                    image: UIImage(named: "wallet_connect_24")?.withTintColor(.themeJacob),
                    description: "wallet_connect.non_supported_account.description".localized(accountTypeDescription),
                    buttonTitle: "wallet_connect.non_supported_account.switch".localized,
                    onTapButton: InformationModule.afterClose { [weak viewController] in
                        viewController?.present(SwitchAccountModule.viewController(), animated: true)
                    })

            viewController?.present(presentingViewController, animated: true)
        }
    }

    enum WalletConnectOpenError {
        case noAccount
        case nonSupportedAccountType(accountTypeDescription: String)
    }

}

extension WalletConnectV2AppShowView: IDeepLinkHandler {

    func handle(deepLink: DeepLinkManager.DeepLink) {
        switch deepLink {
        case let .walletConnect(url):
            viewModel.onWalletConnectDeepLink(url: url)
        }
    }

}