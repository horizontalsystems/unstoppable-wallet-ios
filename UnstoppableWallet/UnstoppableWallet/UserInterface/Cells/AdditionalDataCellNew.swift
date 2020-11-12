import UIKit
import SnapKit

class AdditionalDataCellNew: UITableViewCell {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    var isVisible = true

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.textColor = .themeGray
        titleLabel.font = .subhead2

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        valueLabel.textColor = .themeGray
        valueLabel.font = .subhead2
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var value: String? {
        get { valueLabel.text }
        set { valueLabel.text = newValue }
    }

    var valueColor: UIColor {
        get { valueLabel.textColor }
        set { valueLabel.textColor = newValue }
    }

    var cellHeight: CGFloat {
        isVisible ? 29 : 0
    }

}
