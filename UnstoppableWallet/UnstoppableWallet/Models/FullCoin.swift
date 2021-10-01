import MarketKit

extension FullCoin {

    var placeholderImageName: String {
        platforms.count == 1 ? platforms[0].coinType.placeholderImageName : "icon_placeholder_24"
    }

}
