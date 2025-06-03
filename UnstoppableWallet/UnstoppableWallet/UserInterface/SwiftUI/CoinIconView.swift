import Kingfisher
import MarketKit
import SwiftUI

struct CoinIconView: View {
    let coin: Coin?
    let placeholderImage: Image?

    init(coin: Coin?, placeholderImage: Image? = nil) {
        self.coin = coin
        self.placeholderImage = placeholderImage
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
                if let placeholderImage {
                    placeholderImage
                } else {
                    Circle().fill(Color.themeBlade)
                }
            }
    }
}
