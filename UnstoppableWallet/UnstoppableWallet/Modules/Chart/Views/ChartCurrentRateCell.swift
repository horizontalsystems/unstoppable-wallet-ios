import UIKit

class ChartCurrentRateCell: UITableViewCell {
    static let cellHeight: CGFloat = 40

    private let rateLabel = UILabel()
    private let diffLabel = RateDiffLabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        rateLabel.font = .title3
        rateLabel.textColor = .themeOz
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        contentView.addSubview(diffLabel)

        diffLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(rateLabel.snp.trailing).offset(CGFloat.margin8)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        diffLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        diffLabel.font = .subhead1
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(rate: String?, diff: Decimal?) {
        rateLabel.text = rate

        diffLabel.set(value: diff)
    }

    var rate: String? {
        get { rateLabel.text }
        set { rateLabel.text = newValue }
    }

    func set(diff: Decimal?) {
        diffLabel.set(value: diff)
    }

}
