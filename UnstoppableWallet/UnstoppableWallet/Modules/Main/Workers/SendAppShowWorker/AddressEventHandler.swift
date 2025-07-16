import Combine
import MarketKit
import RxSwift
import UIKit

class AddressEventHandler {
    private let disposeBag = DisposeBag()
    private let marketKit: MarketKit.Kit

    private var signalSubject = PassthroughSubject<EventHandlerSignal, Never>()

    init(marketKit: MarketKit.Kit) {
        self.marketKit = marketKit
    }

    private func uri(text: String) -> AddressUri? {
        guard AddressUriParser.hasUriPrefix(text: text) else {
            return nil
        }

        let abstractParser = AddressUriParser(blockchainType: nil, tokenType: nil)
        do {
            let addressUri = try abstractParser.parse(url: text)
            guard BlockchainType.supported.map(\.uriScheme).contains(addressUri.scheme) else {
                return nil
            }
            return addressUri
        } catch {
            return nil
        }
    }

    private func handlerResult(source: StatPage, eventType: EventHandler.EventType, uri: AddressUri, allowedBlockchainTypes: [BlockchainType]? = nil) -> EventHandlerSignal {
        let allowedBlockchainTypes = allowedBlockchainTypes ?? uri.allowedBlockchainTypes

        var allowedTokenType: TokenType?
        if let tokenUid: String = uri.value(field: .tokenUid),
           let tokenType = TokenType(id: tokenUid)
        {
            allowedTokenType = tokenType
        }

        var token: Token?
        if let allowedTokenType,
           let blockchainUid: String = uri.value(field: .blockchainUid),
           let blockchain = try? marketKit.blockchain(uid: blockchainUid),
           let selectedToken = try? marketKit.token(query: .init(blockchainType: blockchain.type, tokenType: allowedTokenType))
        {
            token = selectedToken
        }

        let event = StatEvent.openSendTokenList(coinUid: token?.coin.uid, chainUid: token?.blockchain.uid)
        stat(page: source, section: eventType.contains(.address) ? .qrScan : .deepLink, event: event)

        return .sendPage(.init(
            blockchainTypes: allowedBlockchainTypes,
            tokenTypes: allowedTokenType.map { [$0] },
            address: uri.address,
            amount: uri.amount
        )
        )
    }
}

extension AddressEventHandler: IEventHandler {
    var signal: AnyPublisher<EventHandlerSignal, Never> {
        signalSubject.eraseToAnyPublisher()
    }

    @MainActor
    func handle(source: StatPage, event: Any, eventType: EventHandler.EventType) async throws {
        // check if we parse deeplink with transfer address
        if eventType.contains(.deepLink) {
            if let event = event as? DeepLinkManager.DeepLink {
                guard case let .transfer(parsed) = event else {
                    throw EventHandler.HandleError.noSuitableHandler
                }
                signalSubject.send(handlerResult(source: source, eventType: eventType, uri: parsed))
                return
            } else {
                throw EventHandler.HandleError.noSuitableHandler
            }
        }

        // check if we parse text address or uri
        if eventType.contains(.address) {
            guard let text = event as? String else {
                throw EventHandler.HandleError.noSuitableHandler
            }

            if let parsed = uri(text: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                signalSubject.send(handlerResult(source: source, eventType: eventType, uri: parsed))
                return
            } else {
                let disposeBag = DisposeBag()
                let chain = AddressParserFactory.parserChain(blockchainType: nil, withEns: false)
                let types = try await withCheckedThrowingContinuation { continuation in
                    chain
                        .handlers(address: text)
                        .subscribe(onSuccess: { items in
                            continuation.resume(returning: items.map(\.blockchainType))
                        }, onError: { error in
                            continuation.resume(throwing: error)
                        })
                        .disposed(by: disposeBag)
                }

                guard !types.isEmpty else {
                    throw EventHandler.HandleError.noSuitableHandler
                }
                var uri = AddressUri(scheme: "")
                uri.address = text
                signalSubject.send(handlerResult(source: source, eventType: eventType, uri: uri, allowedBlockchainTypes: types))
                return
            }
        }

        throw EventHandler.HandleError.noSuitableHandler
    }
}
