import MarketKit
import ObjectMapper
import RxSwift
import UIKit

class TelegramUserHandler {
    private let marketKit: MarketKit.Kit
    private let baseUrl = AppConfig.referralAppServerUrl

    init(marketKit: MarketKit.Kit) {
        self.marketKit = marketKit
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
                throw EventHandler.HandleError.noSuitableHandler
            }

            let _: EmptyResponse = try await Core.shared.networkManager.fetch(url: url)
            return
        }
        throw EventHandler.HandleError.noSuitableHandler
    }
}

struct EmptyResponse: ImmutableMappable {
    init(map _: Map) throws {}
}
