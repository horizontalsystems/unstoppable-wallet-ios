import MarketKit

extension FullCoin {

    var placeholderImageName: String {
        let supportedPlatforms = supportedPlatforms
        return supportedPlatforms.count == 1 ? supportedPlatforms[0].coinType.placeholderImageName : "icon_placeholder_24"
    }

}
