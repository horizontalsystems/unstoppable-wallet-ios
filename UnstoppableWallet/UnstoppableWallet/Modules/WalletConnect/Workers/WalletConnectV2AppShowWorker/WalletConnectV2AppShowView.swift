import UIKit
import RxSwift
import RxCocoa
import ThemeKit
import WalletConnectSign
import ComponentKit

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
        case .pair(let uri):
            switch WalletConnectUriHandler.uriVersion(uri: uri) {
            case 1:
                WalletConnectUriHandler.createServiceV1(uri: uri)
                        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                        .observeOn(MainScheduler.instance)
                        .subscribe(onSuccess: { [weak self] service in
                            self?.processWalletConnectV1(service: service)
                        }, onError: { [weak self] error in
                            self?.handle(error: error)
                        })
                        .disposed(by: disposeBag)
            case 2:
                WalletConnectUriHandler.pairV2(uri: uri)
                        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                        .observeOn(MainScheduler.instance)
                        .subscribe(onSuccess: { [weak self] service in
                            self?.showV2PairedSuccessful()
                        }, onError: { [weak self] error in
                            self?.handle(error: error)
                        })
                        .disposed(by: disposeBag)
            default:
                handle(error: WalletConnectUriHandler.ConnectionError.wrongUri)
            }
        case .proposal(let proposal):
            processWalletConnectPair(proposal: proposal)
        case .errorDialog(let error):
            WalletConnectV2AppShowView.showWalletConnectError(error: error, viewController: parentViewController)
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


    private func processWalletConnectV1(service: WalletConnectV1MainService) {
        guard let viewController = WalletConnectMainModule.viewController(
                service: service,
                sourceViewController: parentViewController?.visibleController)
        else {
            return
        }

        parentViewController?.visibleController.present(viewController, animated: true)
    }

    private func showV2PairedSuccessful() {
        HudHelper.instance.show(banner: .success(string: "Pairing successful. Please wait for a new session!"))
    }

    private func handle(error: Error) {
        HudHelper.instance.show(banner: .error(string: error.smartDescription))
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
                    buttonTitle: "wallet_connect.error_dialog.i_understand".localized,
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
        case .unbackupedAccount:
            let presentingViewController = InformationModule.simpleInfo(
                    title: "wallet_connect.title".localized,
                    image: UIImage(named: "wallet_connect_24")?.withTintColor(.themeJacob),
                    description: "wallet_connect.unbackuped_account.description".localized,
                    buttonTitle: "wallet_connect.error_dialog.i_understand".localized,
                    onTapButton: InformationModule.afterClose())

            viewController?.present(presentingViewController, animated: true)
        }
    }

    enum WalletConnectOpenError {
        case noAccount
        case nonSupportedAccountType(accountTypeDescription: String)
        case unbackupedAccount
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
