import UIKit
import SnapKit
import Chart
import ThemeKit
import ComponentKit

class MarketCardTitleView: UIView {
    private static let font: UIFont = .caption
    static let height: CGFloat = ceil(MarketCardTitleView.font.lineHeight)

    private let titleLabel = UILabel()
    private let badgeView = BadgeView()

    init() {
        super.init(frame: .zero)

        snp.makeConstraints { maker in
            maker.height.equalTo(Self.height)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.bottom.top.equalToSuperview()
        }

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.font = Self.font
        titleLabel.textColor = .themeGray

        addSubview(badgeView)
        badgeView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin8)
            maker.centerY.equalTo(titleLabel.snp.centerY)
        }

        badgeView.set(style: .small)
        badgeView.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var badge: String? {
        get { badgeView.text }
        set {
            badgeView.isHidden = newValue == nil
            badgeView.text = newValue
        }
    }

    var badgeColor: UIColor {
        get { badgeView.textColor }
        set { badgeView.textColor = newValue }
    }

}
