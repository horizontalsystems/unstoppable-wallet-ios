import UIKit
import SnapKit
import AlamofireImage

class CoinIconImageView: UIImageView {

    private static let filter = DynamicImageFilter("TemplateImageFilter") { image in
        return image.withRenderingMode(.alwaysTemplate)
    }

    init() {
        super.init(frame: .zero)

        tintColor = AppTheme.coinIconColor
        layer.cornerRadius = AppTheme.coinIconSize / 2

        snp.makeConstraints { maker in
            maker.size.equalTo(AppTheme.coinIconSize)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(coin: Coin) {
        image = nil
        backgroundColor = AppTheme.coinIconColor

        switch coin.type {
        case let .erc20(address, _):
            let baseApiUrl = App.shared.appConfigProvider.apiUrl
            let screenScale = Int(UIScreen.main.scale)

            let urlString = "\(baseApiUrl)/blockchain/ETH/erc20/\(address)/icons/ios/icon@\(screenScale)x.png"

            if let url = URL(string: urlString) {
                af_setImage(
                        withURL: url,
                        filter: CoinIconImageView.filter,
                        completion: { [weak self] response in
                            if response.value != nil {
                                self?.backgroundColor = .clear
                            }
                        }
                )
            }
        default:
            image = UIImage(named: "\(coin.code) Icon")?.withRenderingMode(.alwaysTemplate)
            backgroundColor = .clear
        }
    }

}
