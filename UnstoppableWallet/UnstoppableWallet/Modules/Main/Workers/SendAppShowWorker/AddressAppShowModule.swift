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
        let result = abstractParser.parse(addressUri: text)
        switch result {
        case let .uri(uri):
            guard BlockchainType.supported.map(\.uriScheme).contains(uri.scheme) else {
                return nil
            }
            return uri
        default: return nil
        }
    }

    private func showSendTokenList(uri: AddressUri, allowedBlockchainTypes: [BlockchainType]?, allowedTokenTypes: [TokenType]?) {
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
        guard eventType.contains(.address) else {
            return
        }

        guard var text = event as? String else {
            throw EventHandler.HandleError.noSuitableHandler
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle uri string if exist
        if let uri = uri(text: text) {
            let allowedBlockchainTypes = uri.allowedBlockchainTypes

            var allowedTokenTypes: [TokenType]?
            if let tokenUid: String = uri.value(field: .tokenUid),
               let tokenType = TokenType(id: tokenUid)
            {
                allowedTokenTypes = [tokenType]
            }

            showSendTokenList(uri: uri, allowedBlockchainTypes: allowedBlockchainTypes, allowedTokenTypes: allowedTokenTypes)
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
            showSendTokenList(uri: uri, allowedBlockchainTypes: types, allowedTokenTypes: nil)
        }
    }
}

extension AddressAppShowModule {
    static func handler(parentViewController: UIViewController? = nil) -> IEventHandler {
        AddressAppShowModule(parentViewController: parentViewController)
    }
}
