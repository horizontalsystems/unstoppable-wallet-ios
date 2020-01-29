import UIKit
import SnapKit
import AlamofireImage

class CoinIconImageView: UIImageView {

    init() {
        super.init(frame: .zero)

        tintColor = .themeGray

        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(coin: Coin) {
        backgroundColor = .clear

        if let image = UIImage(named: "\(coin.code.lowercased())") {
            layer.cornerRadius = image.size.width
            self.image = image.withRenderingMode(.alwaysTemplate)
        } else {
            image = nil
        }
    }

}
