import UIKit
import SnapKit
import HUD

class RateListChangingCellView: UIView {
    private let rateLabel = UILabel()
    private let diffPlaceholderLabel = UILabel()
    private let rateDiffView = RateDiffView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        rateLabel.font = .appSubhead1
        rateLabel.textAlignment = .right
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(10)
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        rateDiffView.font = .appSubhead1
        rateDiffView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateDiffView.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(rateDiffView)
        rateDiffView.snp.makeConstraints { maker in
            maker.top.equalTo(rateLabel.snp.bottom).offset(CGFloat.margin1x)
            maker.leading.greaterThanOrEqualToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        diffPlaceholderLabel.textColor = .appGray
        diffPlaceholderLabel.font = .appSubhead1
        diffPlaceholderLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        diffPlaceholderLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(diffPlaceholderLabel)
        diffPlaceholderLabel.snp.makeConstraints { maker in
            maker.top.equalTo(rateLabel.snp.bottom).offset(CGFloat.margin1x)
            maker.leading.greaterThanOrEqualToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(rate: String?, rateColor: UIColor, diff: Decimal?) {
        rateLabel.text = rate
        rateLabel.textColor = rateColor

        let showDiff = diff != nil

        rateDiffView.set(value: diff)
        rateDiffView.set(hidden: !showDiff)

        diffPlaceholderLabel.text = showDiff ? nil : "----"
        diffPlaceholderLabel.set(hidden: showDiff)
    }

}
