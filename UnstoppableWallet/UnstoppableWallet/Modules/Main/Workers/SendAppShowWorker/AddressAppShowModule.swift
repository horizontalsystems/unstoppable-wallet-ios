import MarketKit
import RxSwift
import UIKit

class AddressAppShowModule {
    private let disposeBag = DisposeBag()
    private let parentViewController: UIViewController?

    init(parentViewController: UIViewController?) {
        self.parentViewController = parentViewController
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

    private func showSendTokenList(uri: AddressUri, allowedBlockchainTypes: [BlockchainType]? = nil) {
        let allowedBlockchainTypes = allowedBlockchainTypes ?? uri.allowedBlockchainTypes

        var allowedTokenTypes: [TokenType]?
        if let tokenUid: String = uri.value(field: .tokenUid),
           let tokenType = TokenType(id: tokenUid)
        {
            allowedTokenTypes = [tokenType]
        }

        guard let viewController = WalletModule.sendTokenListViewController(
            allowedBlockchainTypes: allowedBlockchainTypes,
            allowedTokenTypes: allowedTokenTypes,
            mode: .prefilled(address: uri.address, amount: uri.amount)
        ) else {
            return
        }
        parentViewController?.visibleController.present(viewController, animated: true)
    }
}

extension AddressAppShowModule: IEventHandler {
    @MainActor
    func handle(event: Any, eventType: EventHandler.EventType) async throws {
        // check if we parse deeplink with transfer address
        if eventType.contains(.deepLink) {
            if let event = event as? DeepLinkManager.DeepLink {
                guard case let .transfer(parsed) = event else {
                    throw EventHandler.HandleError.noSuitableHandler
                }
                showSendTokenList(uri: parsed)
            } else {
                return
            }
        }

        // check if we parse text address or uri
        if eventType.contains(.address) {
            guard let text = event as? String else {
                throw EventHandler.HandleError.noSuitableHandler
            }

            if let parsed = uri(text: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                showSendTokenList(uri: parsed)
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
                showSendTokenList(uri: uri, allowedBlockchainTypes: types)
                return
            }
        }
    }
}

extension AddressAppShowModule {
    static func handler(parentViewController: UIViewController? = nil) -> IEventHandler {
        AddressAppShowModule(parentViewController: parentViewController)
    }
}
