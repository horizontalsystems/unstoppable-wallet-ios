import Foundation
import Kingfisher
import MarketKit

extension KFImage {
    static func url(_ coin: Coin?) -> Self {
        if let alternativeUrlString = coin?.image, let alternativeUrl = URL(string: alternativeUrlString) {
            if ImageCache.default.isCached(forKey: alternativeUrlString) {
                url(alternativeUrl)
            } else {
                url(coin.flatMap { URL(string: $0.imageUrl) }).alternativeSources([.network(alternativeUrl)])
            }
        } else {
            url(coin.flatMap { URL(string: $0.imageUrl) })
        }
    }
}
