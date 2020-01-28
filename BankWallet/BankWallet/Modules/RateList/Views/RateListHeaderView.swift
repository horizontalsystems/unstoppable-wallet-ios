import UIKit

class RateListHeaderView: UITableViewHeaderFooterView {
    private let currentDateLabel = UILabel()
    private let lastUpdateLabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.addSubview(currentDateLabel)
        currentDateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin6x)
            maker.top.equalToSuperview().offset(CGFloat.margin6x)
        }

        currentDateLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        currentDateLabel.textColor = .themeOz
        currentDateLabel.font = .title1

        contentView.addSubview(lastUpdateLabel)
        lastUpdateLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(currentDateLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
        }

        lastUpdateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lastUpdateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        lastUpdateLabel.textColor = .themeGray
        lastUpdateLabel.font = .caption
        lastUpdateLabel.numberOfLines = 2
        lastUpdateLabel.textAlignment = .right
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(title: String, lastUpdated: String?) {
        currentDateLabel.text = title
        lastUpdateLabel.text = lastUpdated
    }

}

extension RateListHeaderView {

    static func height(forContainerWidth containerWidth: CGFloat, text: String) -> CGFloat {
        text.height(forContainerWidth: containerWidth, font: .title1) + CGFloat.margin6x + CGFloat.margin4x
    }

}
