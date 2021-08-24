import UIKit
import SnapKit

class SelectResourceCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let iconView = UIImageView()

    var isVisible = true

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.textColor = .themeGray
        titleLabel.font = .subhead2

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin8)
            maker.centerY.equalToSuperview()
        }

        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        valueLabel.textColor = .themeJacob
        valueLabel.font = .subhead2

        addSubview(iconView)
        iconView.snp.makeConstraints { maker in
            maker.leading.equalTo(valueLabel.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.size.equalTo(CGFloat.iconSize24)
            maker.centerY.equalToSuperview()
        }

        iconView.clipsToBounds = true
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconView.setContentHuggingPriority(.required, for: .horizontal)

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var value: String? {
        get { valueLabel.attributedText?.string }
        set {
            let attributedText = newValue.map { NSAttributedString(string: $0, attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]) }
            valueLabel.attributedText = attributedText
        }
    }

    var valueColor: UIColor {
        get { valueLabel.textColor }
        set { valueLabel.textColor = newValue }
    }

    var icon: UIImage? {
        get { iconView.image }
        set { iconView.image = newValue }
    }

    var iconTintColor: UIColor? {
        get { iconView.tintColor }
        set { iconView.tintColor = newValue }
    }

    var cellHeight: CGFloat {
        isVisible ? 29 : 0
    }

}
