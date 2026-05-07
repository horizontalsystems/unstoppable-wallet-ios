import Intents

class IntentHandler: INExtension, SingleCoinPriceIntentHandling {
    func provideSelectedCoinOptionsCollection(for _: SingleCoinPriceIntent) async throws -> INObjectCollection<WidgetCoin> {
        let provider = ApiProvider()

        let coins = try await provider.topCoins(limit: 100)

        let widgetCoins = coins.map { coin in
            let widgetCoin = WidgetCoin(
                identifier: coin.uid,
                display: coin.code.uppercased(),
                subtitle: coin.name,
                image: nil
            )

            return widgetCoin
        }

        return INObjectCollection(items: widgetCoins)
    }

    override func handler(for _: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.

        self
    }
}
