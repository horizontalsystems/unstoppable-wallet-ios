import MarketKit

extension FullCoin {

    var placeholderImageName: String {
        let supportedTokens = supportedTokens
        return supportedTokens.count == 1 ? supportedTokens[0].placeholderImageName : "icon_placeholder_24"
    }

}
