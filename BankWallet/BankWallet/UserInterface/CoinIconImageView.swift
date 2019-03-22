import UIKit
import SnapKit
import AlamofireImage

class CoinIconImageView: UIImageView {

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
        backgroundColor = .clear
        image = UIImage(named: "\(coin.code.lowercased())")?.withRenderingMode(.alwaysTemplate)
    }

}
