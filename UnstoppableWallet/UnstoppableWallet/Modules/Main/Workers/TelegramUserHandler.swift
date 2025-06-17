import MarketKit
import ObjectMapper
import RxSwift
import UIKit

class TelegramUserHandler {
    private let disposeBag = DisposeBag()
    private let parentViewController: UIViewController?
    private let marketKit = Core.shared.marketKit
    private let baseUrl = AppConfig.referralAppServerUrl

    init(parentViewController: UIViewController?) {
        self.parentViewController = parentViewController
    }
}

extension TelegramUserHandler: IEventHandler {
    @MainActor
    func handle(source _: StatPage, event: Any, eventType: EventHandler.EventType) async throws {
        if eventType.contains(.deepLink), let event = event as? DeepLinkManager.DeepLink {
            guard case let .referral(userId, referralCode) = event else {
                throw EventHandler.HandleError.noSuitableHandler
            }
            let urlString = "\(baseUrl)/v1/tasks/registerApp?userId=\(userId)&referralCode=\(referralCode)"
            print("Requesting: \(urlString)")
            guard let url = URL(string: urlString) else {
                return
            }

            let _: EmptyResponse = try await Core.shared.networkManager.fetch(url: url)
        }
    }
}

extension TelegramUserHandler {
    static func handler(parentViewController: UIViewController? = nil) -> IEventHandler {
        TelegramUserHandler(parentViewController: parentViewController)
    }
}

struct EmptyResponse: ImmutableMappable {
    init(map _: Map) throws {}
}
