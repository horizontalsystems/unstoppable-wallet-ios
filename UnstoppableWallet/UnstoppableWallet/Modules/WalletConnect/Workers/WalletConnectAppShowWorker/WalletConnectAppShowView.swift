import Combine
import ComponentKit
import ThemeKit
import UIKit
import WalletConnectSign

class WalletConnectAppShowView {
    private let timeOut = 5

    private let viewModel: WalletConnectAppShowViewModel
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    private var isWaitingHandlerCancellable: AnyCancellable?

    @Published private var isWaitingForSession = false

    weak var parentViewController: UIViewController?

    init(viewModel: WalletConnectAppShowViewModel) {
        self.viewModel = viewModel

        viewModel.showSessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(request: $0) }
            .store(in: &cancellables)

        viewModel.openWalletConnectPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.openWalletConnect(mode: $0) }
            .store(in: &cancellables)
    }

    private func openWalletConnect(mode: WalletConnectAppShowViewModel.WalletConnectOpenMode) {
        switch mode {
        case let .pair(uri):
            Task { [weak self] in
                switch WalletConnectUriHandler.uriVersion(uri: uri) {
                case 2:
                    do {
                        try await WalletConnectUriHandler.pair(uri: uri)
                        await self?.showPairedSuccessful()
                    } catch {
                        await self?.handle(error: error)
                    }
                default: await self?.handle(error: WalletConnectUriHandler.ConnectionError.wrongUri)
                }
            }
        case let .proposal(proposal):
            showProposalSuccessful()
            processWalletConnectPair(proposal: proposal)
        case let .errorDialog(error):
            WalletConnectAppShowView.showWalletConnectError(error: error, sourceViewController: parentViewController)
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

    @MainActor private func showPairedSuccessful() {
        HudHelper.instance.show(banner: .waitingForSession)

        timerCancellable = Just(())
            .delay(for: .seconds(timeOut), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.isWaitingForSession = false
                HudHelper.instance.show(banner: .error(string: "alert.try_again".localized))
            }
    }

    private func showProposalSuccessful() {
        isWaitingForSession = false
        HudHelper.instance.hide()
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    @MainActor private func handle(error: Error) {
        HudHelper.instance.show(banner: .error(string: error.smartDescription))
    }

    private func handle(request: WalletConnectRequest) {
        guard let viewController = WalletConnectRequestModule.viewController(signService: App.shared.walletConnectSessionManager.service, request: request) else {
            return
        }

        parentViewController?.visibleController.present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }
}

extension WalletConnectAppShowView {
    static func showWalletConnectError(error: WalletConnectOpenError, sourceViewController: UIViewController?) {
        let viewController: UIViewController

        switch error {
        case .noAccount:
            viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "wallet_connect_24")?.withTintColor(.themeJacob)),
                title: "wallet_connect.title".localized,
                items: [
                    .highlightedDescription(text: "wallet_connect.no_account.description".localized),
                ],
                buttons: [
                    .init(style: .yellow, title: "button.ok".localized),
                ]
            )
        case let .nonSupportedAccountType(accountTypeDescription):
            viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "wallet_connect_24")?.withTintColor(.themeJacob)),
                title: "wallet_connect.title".localized,
                items: [
                    .highlightedDescription(text: "wallet_connect.non_supported_account.description".localized(accountTypeDescription)),
                ],
                buttons: [
                    .init(style: .yellow, title: "wallet_connect.non_supported_account.switch".localized, actionType: .afterClose) { [weak sourceViewController] in
                        sourceViewController?.present(SwitchAccountModule.viewController(), animated: true)
                    },
                    .init(style: .transparent, title: "button.cancel".localized),
                ]
            )
        case let .unbackupedAccount(account):
            viewController = BottomSheetModule.backupRequiredPrompt(
                description: "wallet_connect.unbackuped_account.description".localized(account.name),
                account: account,
                sourceViewController: sourceViewController
            )
        }

        sourceViewController?.present(viewController, animated: true)
    }

    enum WalletConnectOpenError: Error {
        case noAccount
        case nonSupportedAccountType(accountTypeDescription: String)
        case unbackupedAccount(account: Account)
    }
}

extension WalletConnectAppShowView: IEventHandler {
    var eventType: EventHandler.EventType { [.walletConnectDeepLink, .walletConnectUri] }

    func handle(event: Any, eventType _: EventHandler.EventType) async throws {
        var uri: String?
        switch event {
        case let event as String:
            uri = event
        case let event as DeepLinkManager.DeepLink:
            if case let .walletConnect(url) = event {
                uri = url
            }
        default: ()
        }

        guard let uri else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        do {
            try viewModel.validate(uri: uri)
        } catch {
            throw EventHandler.HandleError.noSuitableHandler
        }

        try viewModel.handleWalletConnect(url: uri)

        isWaitingForSession = true
        await withCheckedContinuation { [weak self] continuation in
            self?.isWaitingHandlerCancellable = self?.$isWaitingForSession
                .sink { isWaiting in
                    if !isWaiting {
                        self?.isWaitingHandlerCancellable = nil
                        continuation.resume()
                    }
                }
        }
    }
}
