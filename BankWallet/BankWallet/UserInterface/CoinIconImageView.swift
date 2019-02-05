import UIKit
import AlamofireImage

class CoinIconImageView: UIImageView {

    private static let filter = DynamicImageFilter("TemplateImageFilter") { image in
        return image.withRenderingMode(.alwaysTemplate)
    }

    private static let erc20placeholderImage = UIImage(named: "Erc20 Placeholder Icon")?.withRenderingMode(.alwaysTemplate)

    func bind(coin: Coin) {
        switch coin.type {
        case let .erc20(address, _):
//            let baseApiUrl = App.shared.appConfigProvider.ratesApiUrl
            let baseApiUrl = "https://ipfs.horizontalsystems.xyz/ipns/Qmd4Gv2YVPqs6dmSy1XEq7pQRSgLihqYKL2JjK7DMUFPVz/io-hs/data"
            let screenScale = Int(UIScreen.main.scale)

            let urlString = "\(baseApiUrl)/blockchain/ETH/erc20/\(address)/icons/ios/icon@\(screenScale)x.png"

            if let url = URL(string: urlString) {
                af_setImage(
                        withURL: url,
                        placeholderImage: CoinIconImageView.erc20placeholderImage,
                        filter: CoinIconImageView.filter
                )
            }
        default:
            image = UIImage(named: "\(coin.code) Icon")?.withRenderingMode(.alwaysTemplate)
        }
    }

}
