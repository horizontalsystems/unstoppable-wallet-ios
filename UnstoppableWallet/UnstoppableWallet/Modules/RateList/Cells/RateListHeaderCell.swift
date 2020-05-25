import UIKit
import ThemeKit

class RateListHeaderCell: UITableViewCell {
    static let height: CGFloat = .heightSingleLineCell

    private let titleLabel = UILabel()
    private let lastUpdateLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.textColor = .themeOz
        titleLabel.font = .title3

        contentView.addSubview(lastUpdateLabel)
        lastUpdateLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalTo(titleLabel.snp.bottom)
        }

        lastUpdateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lastUpdateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        lastUpdateLabel.textColor = .themeGray
        lastUpdateLabel.font = .caption
        lastUpdateLabel.textAlignment = .right
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(title: String, lastUpdated: String?) {
        titleLabel.text = title
        lastUpdateLabel.text = lastUpdated
    }

}
