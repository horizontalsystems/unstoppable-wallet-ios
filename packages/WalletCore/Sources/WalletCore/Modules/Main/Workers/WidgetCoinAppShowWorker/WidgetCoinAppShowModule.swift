import Combine
import MarketKit
import UIKit

class WidgetCoinEventHandler {
    private let marketKit: MarketKit.Kit

    private var signalSubject = PassthroughSubject<EventHandlerSignal, Never>()

    init(marketKit: MarketKit.Kit) {
        self.marketKit = marketKit
    }
}

extension WidgetCoinEventHandler: IEventHandler {
    var signal: AnyPublisher<EventHandlerSignal, Never> {
        signalSubject.eraseToAnyPublisher()
    }

    @MainActor func handle(source _: StatPage, event: Any, eventType: EventHandler.EventType) async throws {
        guard eventType.contains(.deepLink) else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        var coinUid: String?

        switch event {
        case let event as String:
            coinUid = event
        case let event as DeepLinkManager.DeepLink:
            if case let .coin(_coinUid) = event {
                coinUid = _coinUid
            }
        default: ()
        }

        guard let coinUid, let coin = try? marketKit.fullCoins(coinUids: [coinUid]).first?.coin else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        stat(page: .widget, event: .openCoin(coinUid: coinUid))
        signalSubject.send(.coinPage(coin))
    }
}
