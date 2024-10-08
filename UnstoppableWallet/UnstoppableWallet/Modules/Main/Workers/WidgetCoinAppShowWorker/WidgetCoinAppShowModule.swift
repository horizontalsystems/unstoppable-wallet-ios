import UIKit

class WidgetCoinAppShowModule {
    private let parentViewController: UIViewController?
    private let marketKit = App.shared.marketKit

    init(parentViewController: UIViewController?) {
        self.parentViewController = parentViewController
    }
}

extension WidgetCoinAppShowModule: IEventHandler {
    @MainActor
    func handle(source _: StatPage, event: Any, eventType: EventHandler.EventType) async throws {
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

        let viewController = CoinPageView(coin: coin).toViewController()
        parentViewController?.visibleController.present(viewController, animated: true)

        stat(page: .widget, event: .openCoin(coinUid: coinUid))
    }
}

extension WidgetCoinAppShowModule {
    static func handler(parentViewController: UIViewController? = nil) -> IEventHandler {
        WidgetCoinAppShowModule(parentViewController: parentViewController)
    }
}
