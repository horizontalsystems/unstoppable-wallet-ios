import Combine
import Foundation
import MarketKit

class OpenCryptoPayEventHandler {
    private let signalSubject = PassthroughSubject<EventHandlerSignal, Never>()
    private let openCryptoPayManager: OpenCryptoPayManager

    init(openCryptoPayManager: OpenCryptoPayManager) {
        self.openCryptoPayManager = openCryptoPayManager
    }
}

extension OpenCryptoPayEventHandler: IEventHandler {
    var signal: AnyPublisher<EventHandlerSignal, Never> {
        signalSubject.eraseToAnyPublisher()
    }

    @MainActor
    func handle(source _: StatPage, event: Any, eventType: EventHandler.EventType) async throws {
        let url: URL

        if eventType.contains(.deepLink),
           let deepLink = event as? DeepLinkManager.DeepLink,
           case let .openCryptoPay(deepLinkUrl) = deepLink
        {
            url = deepLinkUrl
        } else if eventType.contains(.address),
                  let text = event as? String,
                  let scanned = OpenCryptoPayUrl.detect(text: text)
        {
            url = scanned
        } else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        let payment = try await openCryptoPayManager.startPayment(url: url)

        let options = SendTokenListViewModel.SendOptions(
            tokens: payment.entries.map(\.token)
        )

        signalSubject.send(.cryptoPaySendPage(.init(options: options) { [openCryptoPayManager] wallet in
            try await openCryptoPayManager.resolve(wallet: wallet, against: payment)
        }))
    }
}
