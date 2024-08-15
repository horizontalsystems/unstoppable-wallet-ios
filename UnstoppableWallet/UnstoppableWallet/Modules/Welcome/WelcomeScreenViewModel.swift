class WelcomeScreenViewModel {
    private let deepLinkService: DeepLinkService
    private let eventHandler: EventHandler

    init(deepLinkService: DeepLinkService, eventHandler: EventHandler) {
        self.deepLinkService = deepLinkService
        self.eventHandler = eventHandler
    }

    func handleDeepLink() {
        guard let deepLink = deepLinkService.deepLink else {
            return
        }

        Task {
            do {
                try await eventHandler.handle(source: .main, event: deepLink, eventType: .deepLink)
                deepLinkService.setDeepLinkShown()
            } catch {
                print("Can't handle Deep Link \(error)")
            }
        }
    }
}
