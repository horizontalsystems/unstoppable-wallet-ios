import Foundation
import MarketKit

class CoinPageViewModel {
    let viewItem: ViewItem

    init(fullCoin: FullCoin) {
        viewItem = ViewItem(
                title: fullCoin.coin.code,
                subtitle: fullCoin.coin.name,
                marketCapRank: fullCoin.coin.marketCapRank.map { "#\($0)" },
                imageUrl: fullCoin.coin.imageUrl,
                imagePlaceholderName: fullCoin.placeholderImageName
        )
    }

}

extension CoinPageViewModel {

    var tabs: [CoinPageModule.Tab] {
        CoinPageModule.Tab.allCases
    }

}

extension CoinPageViewModel {

    struct ViewItem {
        let title: String
        let subtitle: String
        let marketCapRank: String?
        let imageUrl: String
        let imagePlaceholderName: String
    }

}
