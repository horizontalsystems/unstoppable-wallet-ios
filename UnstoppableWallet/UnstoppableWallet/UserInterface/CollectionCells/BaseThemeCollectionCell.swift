import UIKit
import SnapKit

open class BaseThemeCollectionCell: UICollectionViewCell {
    let topSeparatorView = UIView()
    let bottomSeparatorView = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear

        contentView.addSubview(topSeparatorView)
        topSeparatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(0)
        }

        topSeparatorView.backgroundColor = .themeSteel20

        contentView.addSubview(bottomSeparatorView)
        bottomSeparatorView.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(0)
        }

        bottomSeparatorView.backgroundColor = .themeSteel20
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func set(backgroundStyle: BackgroundStyle, topSeparator: Bool = true, bottomSeparator: Bool = false) {
        switch backgroundStyle {
        case .lawrence:
            backgroundColor = .themeLawrence
        case .claude:
            backgroundColor = .themeClaude
        case .transparent:
            backgroundColor = .clear
        }

        topSeparatorView.snp.updateConstraints { maker in
            maker.height.equalTo(topSeparator ? 1 / UIScreen.main.scale : 0)
        }

        bottomSeparatorView.snp.updateConstraints { maker in
            maker.height.equalTo(bottomSeparator ? 1 / UIScreen.main.scale : 0)
        }
    }

    public func layout(leftView: UIView, rightView: UIView) {
        contentView.addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.bottom.equalToSuperview()
        }

        contentView.addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.leading.equalTo(leftView.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.bottom.equalToSuperview()
        }
    }

    public enum BackgroundStyle {
        case lawrence
        case claude
        case transparent
    }

}
