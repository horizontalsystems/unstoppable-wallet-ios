import Kingfisher
import MarketKit
import SwiftUI

struct CoinIconView: View {
    let coin: Coin?
    let placeholder: String

    init(coin: Coin?, placeholder: String = "placeholder_circle_32") {
        self.coin = coin
        self.placeholder = placeholder
    }

    var body: some View {
        if let alternativeUrlString = coin?.image, let alternativeUrl = URL(string: alternativeUrlString) {
            if ImageCache.default.isCached(forKey: alternativeUrlString) {
                icon(alternativeUrl)
                    .clipShape(Circle())
                    .frame(width: .iconSize32, height: .iconSize32)
            } else {
                icon(coin.flatMap { URL(string: $0.imageUrl) }).alternativeSources([.network(alternativeUrl)])
                    .clipShape(Circle())
                    .frame(width: .iconSize32, height: .iconSize32)
            }
        } else {
            icon(coin.flatMap { URL(string: $0.imageUrl) })
                .clipShape(Circle())
                .frame(width: .iconSize32, height: .iconSize32)
        }
    }

    @ViewBuilder func icon(_ url: URL?) -> some KFImageProtocol {
        KFImage.url(url)
            .resizable()
            .placeholder {
                Image(placeholder)
            }
    }
}
