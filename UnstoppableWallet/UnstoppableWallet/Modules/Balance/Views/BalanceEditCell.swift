import UIKit
import SnapKit
import ThemeKit

class BalanceEditCell: UICollectionViewCell {
    static let height: CGFloat = 72

    private let button = ThemeButton()

    var onTap: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        button.setTitle("balance.add_coin".localized, for: .normal)
        button.setTitleColor(.themeGray, for: .normal)
        button.setTitleColor(.themeGray50, for: .highlighted)
        button.titleLabel?.font = .subhead1
        button.contentEdgeInsets = UIEdgeInsets(top: .margin4x, left: .margin8x, bottom: .margin4x, right: .margin8x)

        let image = UIImage(named: "circle_plus_20")
        button.setImageTintColor(.themeGray, for: .normal)
        button.setImageTintColor(.themeGray50, for: .highlighted)
        button.setImage(image, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -.margin4x, bottom: 0, right: 0)

        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc func didTap() {
        onTap?()
    }

}
