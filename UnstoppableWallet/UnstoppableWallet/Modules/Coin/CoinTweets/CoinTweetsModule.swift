import MarketKit

struct CoinTweetsModule {

    static func viewController(fullCoin: FullCoin, twitterUsernameService: TwitterUsernameService) -> CoinTweetsViewController {
        let tweetsProvider = TweetsProvider(
                networkManager: App.shared.networkManager,
                bearerToken: App.shared.appConfigProvider.twitterBearerToken
        )

        let service = CoinTweetsService(
                provider: tweetsProvider,
                usernameService: twitterUsernameService
        )

        let viewModel = CoinTweetsViewModel(service: service)

        return CoinTweetsViewController(
                viewModel: viewModel,
                urlManager: UrlManager(inApp: true)
        )
    }

}

extension CoinTweetsModule {

    enum LoadError: Error {
        case tweeterUserNotFound
    }

}
