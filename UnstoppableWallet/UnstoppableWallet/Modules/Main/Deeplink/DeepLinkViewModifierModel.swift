import Combine
import Foundation
import MarketKit
import SwiftUI
import WalletConnectSign

class DeepLinkViewModifierModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    private let eventHandler = Core.shared.appEventHandler
    let walletConnectViewModifierModel = WalletConnectViewModifierModel()
    let walletConnectManager = Core.shared.walletConnectManager

    @Published var presentedCoin: Coin?
    @Published var presentedSendPage: EventHandler.SendParams?
    @Published var presentedTonConnect: EventHandler.TonConnectParams?
    @Published var presentedProposal: EventHandler.WalletConnectProposalParams?
    @Published var presentedWalletConnectRequest: WalletConnectRequest?

    init() {
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
        case let .coinPage(coin): presentedCoin = coin
        case let .sendPage(params): presentedSendPage = params

        case let .walletConnectHandleUrl(url):
            walletConnectViewModifierModel.handle { [weak self] in
                self?.handleWalletConnect(url: url)
            }

        case let .walletConnectProposal(proposal): ()
            guard let account = Core.shared.accountManager.activeAccount else {
                walletConnectViewModifierModel.handle(onSuccess: {}) // just show - No Account
                return
            }

            presentedProposal = .init(proposal: proposal, account: account)
        case let .walletConnectRequest(request):
            switch request.payload {
            case is WCSignEthereumTransactionPayload,
                 is WCSendEthereumTransactionPayload,
                 is WCSignMessagePayload: presentedWalletConnectRequest = request
            default: ()
            }

        case let .tonConnect(params): presentedTonConnect = params
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
