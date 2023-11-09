import MarketKit
import SwiftUI

struct CoinMarketsModule {
    static func view(coin: Coin) -> some View {
        let viewModel = CoinMarketsViewModel(
            coin: coin,
            marketKit: App.shared.marketKit,
            currencyManager: App.shared.currencyManager
        )

        return CoinMarketsView(viewModel: viewModel)
    }
}
