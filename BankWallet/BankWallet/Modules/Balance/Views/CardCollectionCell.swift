import UIKit
import SnapKit

open class CardCollectionCell: UICollectionViewCell {
    static public let animationDuration = 0.15

    private let roundedBackground = UIView()
    public let clippingView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        roundedBackground.backgroundColor = .themeLawrence
        roundedBackground.layer.cornerRadius = .cornerRadius4x
        roundedBackground.layer.shadowColor = UIColor.themeAndy.cgColor
        roundedBackground.layer.shadowRadius = .cornerRadius1x
        roundedBackground.layer.shadowOffset = CGSize(width: 0, height: 4)
        roundedBackground.layer.shadowOpacity = 1

        contentView.addSubview(roundedBackground)
        roundedBackground.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        clippingView.backgroundColor = .clear
        clippingView.clipsToBounds = true
        clippingView.layer.cornerRadius = .cornerRadius4x

        roundedBackground.addSubview(clippingView)
        clippingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
