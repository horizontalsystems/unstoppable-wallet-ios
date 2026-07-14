import MarketKit

// Resolved payload of a transfer deep link / scanned transfer uri, handed to the app-registered presenter.
public struct SendDeepLink {
    public let blockchainTypes: [BlockchainType]?
    public let tokenTypes: [TokenType]?
    public let address: String?
    public let amount: AddressUri.Amount?
    public let memo: String?
}

// Presentation seam for the view layer each app owns (its Coordinator / send flow):
// DeepLinkViewManager hands resolved transfer links to the registered presenter.
// Empty by default — every app that registers the .address handler kind must also register
// its presenter (checked by assertCoherence at assembly time).
public enum DeepLinkPresenterFactory {
    private static var registeredSendPresenter: ((SendDeepLink) -> Void)?

    // Default presentation: token list of the shared send flow.
    public static let sendPresenter: (SendDeepLink) -> Void = { link in
        Coordinator.shared.present { isPresented in
            SendTokenListView(
                options: .init(blockchainTypes: link.blockchainTypes, tokenTypes: link.tokenTypes, address: link.address, amount: link.amount, memo: link.memo),
                isPresented: isPresented
            )
        }
    }

    public static func register(sendPresenter: @escaping (SendDeepLink) -> Void) {
        registeredSendPresenter = sendPresenter
    }

    @MainActor static func presentSend(link: SendDeepLink) {
        registeredSendPresenter?(link)
    }

    static func assertCoherence(handlerKinds: Set<AppEventHandlerKind>) {
        if handlerKinds.contains(.address), registeredSendPresenter == nil {
            assertionFailure("Handler kind 'address' is registered but no send deep link presenter is")
        }
    }
}
