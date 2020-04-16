import UIKit
import SnapKit
import HUD

class RateListChangingCellView: UIView {
    private let rateLabel = UILabel()
    private let diffPlaceholderLabel = UILabel()
    private let rateDiffView = RateDiffView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(rateDiffView)
        rateDiffView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(10)
            maker.leading.greaterThanOrEqualToSuperview()
            maker.trailing.equalToSuperview()
        }

        rateDiffView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateDiffView.setContentCompressionResistancePriority(.required, for: .horizontal)
        rateDiffView.font = .body

        addSubview(diffPlaceholderLabel)
        diffPlaceholderLabel.snp.makeConstraints { maker in
            maker.top.equalTo(rateDiffView.snp.top)
            maker.leading.greaterThanOrEqualToSuperview()
            maker.trailing.equalToSuperview()
        }

        diffPlaceholderLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        diffPlaceholderLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        diffPlaceholderLabel.textColor = .themeGray50
        diffPlaceholderLabel.font = .body

        addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview().inset(CGFloat.margin2x)
        }

        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        rateLabel.font = .subhead2
        rateLabel.textAlignment = .right
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

        diffPlaceholderLabel.text = showDiff ? nil : "n/a".localized
        diffPlaceholderLabel.set(hidden: showDiff)
    }

}
