import SnapKit
import ThemeKit
import UIKit

open class BaseSelectableThemeCell: BaseThemeCell {
    private let selectView = UIView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .default

        wrapperView.insertSubview(selectView, at: 0)
        selectView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview().priority(.high)
        }

        selectView.alpha = 0
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func set(backgroundStyle: BackgroundStyle, cornerRadius: CGFloat = .cornerRadius12, isFirst: Bool = false, isLast: Bool = false) {
        super.set(backgroundStyle: backgroundStyle, cornerRadius: cornerRadius, isFirst: isFirst, isLast: isLast)

        switch backgroundStyle {
        case .lawrence, .bordered, .externalBorderOnly, .borderedLawrence:
            selectView.backgroundColor = .themeLawrencePressed
            selectView.layer.cornerRadius = wrapperView.cornerRadius
            selectView.layer.maskedCorners = corners(isFirst: isFirst, isLast: isLast)
        case .transparent:
            selectView.backgroundColor = .themeLawrencePressed
            selectView.layer.cornerRadius = 0
            selectView.layer.maskedCorners = []
        }

        var topInset: CGFloat = 0
        if !topSeparatorView.isHidden {
            topInset = topSeparatorView.height
        }
        if wrapperView.borders.contains(.top) {
            topInset = wrapperView.borderWidth
        }
        selectView.snp.updateConstraints { maker in
            maker.top.equalToSuperview().inset(topInset)
            maker.leading.equalToSuperview().inset(wrapperView.borders.contains(.left) ? wrapperView.borderWidth : 0)
            maker.trailing.equalToSuperview().inset(wrapperView.borders.contains(.right) ? wrapperView.borderWidth : 0)
            maker.bottom.equalToSuperview().inset(wrapperView.borders.contains(.bottom) ? wrapperView.borderWidth : 0).priority(.high)
        }

        layoutIfNeeded()
    }

    override open func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }

        if animated {
            UIView.animate(withDuration: .themeAnimationDuration) {
                self.selectView.alpha = highlighted ? 1 : 0
            }
        } else {
            selectView.alpha = highlighted ? 1 : 0
        }
    }

    override open func setSelected(_ selected: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }

        if animated {
            UIView.animate(withDuration: .themeAnimationDuration) {
                self.selectView.alpha = selected ? 1 : 0
            }
        } else {
            selectView.alpha = selected ? 1 : 0
        }
    }
}
