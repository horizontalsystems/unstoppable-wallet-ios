import Combine
import Foundation
import MarketKit
import SwiftUI
import WalletConnectSign

class DeepLinkViewManager {
    private var cancellables = Set<AnyCancellable>()

    let walletConnectVerificationModel: WalletConnectVerificationModel

    private let eventHandler: EventHandler
    private let walletConnectManager: WalletConnectManager

    init(eventHandler: EventHandler, walletConnectManager: WalletConnectManager, accountManager: AccountManager, cloudBackupManager: CloudBackupManager) {
        self.eventHandler = eventHandler
        self.walletConnectManager = walletConnectManager

        walletConnectVerificationModel = WalletConnectVerificationModel(accountManager: accountManager, cloudBackupManager: cloudBackupManager)

        eventHandler.signal
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] signal in
                self?.handleAsync(signal)
            }
            .store(in: &cancellables)

        walletConnectManager.$isWaitingForSession
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] waitingForSession in
                self?.showWaitingForSession(waitingForSession)
            }
            .store(in: &cancellables)

        walletConnectManager.errorPublisher
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.show(error: error)
            }
            .store(in: &cancellables)
    }

    private func handleAsync(_ signal: EventHandlerSignal) {
        Task { [weak self] in
            try await self?.handle(signal: signal)
        }
    }

    @MainActor private func handle(signal: EventHandlerSignal) throws {
        switch signal {
        case let .coinPage(coin): Coordinator.shared.presentCoinPage(coin: coin, page: .deepLink)
        case let .sendPage(options):
            Coordinator.shared.present { isPresented in
                SendTokenListView(options: options, isPresented: isPresented)
            }
        case let .walletConnectHandleUrl(url):
            walletConnectVerificationModel.handle { [weak self] in
                self?.handleWalletConnect(url: url)
            }

        case let .walletConnectProposal(proposal): ()
            guard let account = Core.shared.accountManager.activeAccount else {
                walletConnectVerificationModel.handle(onSuccess: {}) // just show - No Account
                return
            }

            Coordinator.shared.present { _ in
                WalletConnectMainView(account: account, session: nil, proposal: proposal)
                    .ignoresSafeArea()
            }
        case let .walletConnectRequest(request):
            switch request.payload {
            case is WCSignEthereumTransactionPayload,
                 is WCSendEthereumTransactionPayload,
                 is WCSignMessagePayload:
                Coordinator.shared.present { _ in
                    switch request.payload {
                    case is WCSignEthereumTransactionPayload: WCSignEthereumTransactionPayload.view(request: request)
                    case is WCSendEthereumTransactionPayload: WCSendEthereumTransactionPayload.view(request: request)
                    case is WCSignMessagePayload: WCSignMessagePayload.view(request: request)
                    default: EmptyView()
                    }
                }

            default: ()
            }

        case let .tonConnect(params):
            Coordinator.shared.present { _ in
                TonConnectConnectView(config: params.config, returnDeepLink: params.returnDeepLink)
            }
        case .tonConnectRequest: () // TODO: make
        case .tonConnectRequestFailed: () // TODO: make

        case .handled: ()
        case let .fail(error): show(error: error)
        }
    }

    private func show(error: Error) {
        DispatchQueue.main.async {
            HudHelper.instance.show(banner: .error(string: error.smartDescription))
        }
    }

    private func showWaitingForSession(_ show: Bool) {
        if show {
            HudHelper.instance.show(banner: .waitingForSession)
        } else if HUD.instance.tag == HudHelper.BannerType.waitingForSessionKey {
            HudHelper.instance.hide()
        }
    }

    private func handleWalletConnect(url: String) {
        walletConnectManager.pair(url: url)
    }
}
