import UIKit

class WidgetCoinAppShowModule {
    private let parentViewController: UIViewController?

    init(parentViewController: UIViewController?) {
        self.parentViewController = parentViewController
    }
}

extension WidgetCoinAppShowModule: IEventHandler {
    
    @MainActor
    func handle(event: Any, eventType: EventHandler.EventType) async throws {
        guard eventType.contains(.deepLink) else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        var uid: String?
        switch event {
        case let event as String:
            uid = event
        case let event as DeepLinkManager.DeepLink:
            if case let .coin(coinUid) = event {
                uid = coinUid
            }
        default: ()
        }

        guard let uid,
            let viewController = CoinPageModule.viewController(coinUid: uid) else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        parentViewController?.visibleController.present(viewController, animated: true)
    }
}

extension WidgetCoinAppShowModule {
    static func handler(parentViewController: UIViewController? = nil) -> IEventHandler {
        WidgetCoinAppShowModule(parentViewController: parentViewController)
    }
}
