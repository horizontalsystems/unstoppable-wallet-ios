import UIKit

class ChartCurrentRateCell: UITableViewCell {
    static let cellHeight: CGFloat = 40

    private let rateLabel = UILabel()
    private let diffImageView = UIImageView()
    private let diffLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        rateLabel.font = .title3
        rateLabel.textColor = .themeOz
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        contentView.addSubview(diffImageView)
        contentView.addSubview(diffLabel)

        diffLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(diffImageView.snp.trailing)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        diffImageView.snp.makeConstraints { maker in
            maker.leading.greaterThanOrEqualTo(rateLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.centerY.equalToSuperview()
        }

        diffImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        diffLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        diffLabel.font = .subhead1
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(rate: String?, diff: Decimal?) {
        rateLabel.text = rate

        guard let diff = diff else {
            diffLabel.text = nil
            diffImageView.image = nil
            return
        }
        let color: UIColor = diff.isSignMinus ? .themeLucian : .themeRemus
        let imageName = diff.isSignMinus ? "arrow_medium_2_down_20" : "arrow_medium_2_up_20"

        diffImageView.image = UIImage(named: imageName)?.tinted(with: color)

        let formattedDiff = ChartCurrentRateCell.formatter.string(from: abs(diff) as NSNumber)
        diffLabel.text = formattedDiff.map { "\($0)%" }
        diffLabel.textColor = color
    }

}

extension ChartCurrentRateCell {

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()

}
