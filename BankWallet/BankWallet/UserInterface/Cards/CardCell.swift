import UIKit
import SnapKit

class CardCell: UITableViewCell {
    private static let horizontalMargin: CGFloat = .margin4x
    private static let bottomMargin: CGFloat = .margin2x

    private let selectView = UIView()

    private let roundedBackground = UIView()
    let clippingView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear

        roundedBackground.backgroundColor = .appLawrence
        roundedBackground.layer.cornerRadius = .cornerRadius16
        roundedBackground.layer.shadowColor = UIColor.appAndy.cgColor
        roundedBackground.layer.shadowRadius = .cornerRadius8
        roundedBackground.layer.shadowOffset = CGSize(width: 0, height: 4)
        roundedBackground.layer.shadowOpacity = App.shared.localStorage.lightMode ? 0.8 : 1

        contentView.addSubview(roundedBackground)
        roundedBackground.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CardCell.horizontalMargin)
            maker.bottom.equalToSuperview().inset(CardCell.bottomMargin)
        }

        clippingView.backgroundColor = .clear
        clippingView.clipsToBounds = true
        clippingView.layer.cornerRadius = .cornerRadius16

        roundedBackground.addSubview(clippingView)
        clippingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        selectView.backgroundColor = .appSteel20
        selectView.alpha = 0

        clippingView.addSubview(selectView)
        selectView.snp.makeConstraints { maker in
            maker.leading.top.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.selectView.alpha = highlighted ? 1 : 0
            }
        } else {
            selectView.alpha = highlighted ? 1 : 0
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.selectView.alpha = selected ? 1 : 0
            }
        } else {
            selectView.alpha = selected ? 1 : 0
        }
    }

}

extension CardCell {

    static func contentWidth(containerWidth: CGFloat) -> CGFloat {
        containerWidth - CardCell.horizontalMargin * 2
    }

    static func height(contentHeight: CGFloat) -> CGFloat {
        contentHeight + CardCell.bottomMargin
    }

}
