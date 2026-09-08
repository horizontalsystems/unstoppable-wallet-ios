import Combine
import Foundation
import MarketKit
import SwiftUI

class DeepLinkViewManager {
    private var cancellables = Set<AnyCancellable>()

    private let eventHandler: EventHandler

    init(eventHandler: EventHandler) {
        self.eventHandler = eventHandler

        eventHandler.signal
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] signal in
                self?.handleAsync(signal)
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
            var blockchainTypes: [BlockchainType]?
            var tokenTypes: [TokenType]?
            if case let .blockchain(filterBlockchainTypes, filterTokenTypes) = options.filter {
                blockchainTypes = filterBlockchainTypes
                tokenTypes = filterTokenTypes
            }

            let link = SendDeepLink(blockchainTypes: blockchainTypes, tokenTypes: tokenTypes, address: options.address, amount: options.amount, memo: options.memo)
            DeepLinkPresenterFactory.presentSend(link: link)
        case let .cryptoPaySendPage(url):
            Coordinator.shared.present { isPresented in
                CryptoPaySendTokenListView(url: url, isPresented: isPresented)
            }
        case let .walletConnectPair(uri): WCPresenter.pair(uri: uri)
        case let .walletConnectProposal(item): WCPresenter.present(proposal: item)
        case let .walletConnectRequest(item): WCPresenter.present(request: item)
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
}
