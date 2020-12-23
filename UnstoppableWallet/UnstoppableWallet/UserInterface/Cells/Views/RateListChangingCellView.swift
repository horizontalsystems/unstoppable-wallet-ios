import UIKit
import SnapKit
import HUD
import CurrencyKit

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

    func bind(viewItem: RateViewItem?) {
        if let viewItem = viewItem {
            rateLabel.text = ValueFormatter.instance.format(currencyValue: viewItem.currencyValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
            rateLabel.textColor = viewItem.dimmed ? .themeGray50 : .themeLeah

            rateDiffView.isHidden = false
            rateDiffView.set(value: viewItem.diff, highlightText: !viewItem.dimmed)

            diffPlaceholderLabel.isHidden = true
            diffPlaceholderLabel.text = nil
        } else {
            rateLabel.text = "----"
            rateLabel.textColor = .themeGray50

            rateDiffView.isHidden = true
            rateDiffView.set(value: nil)

            diffPlaceholderLabel.isHidden = false
            diffPlaceholderLabel.text = "n/a".localized
        }
    }

    func bind(rate: String, diff: Decimal) {
        rateLabel.text = rate
        rateLabel.textColor = .themeLeah

        rateDiffView.isHidden = false
        rateDiffView.set(value: diff, highlightText: true)

        diffPlaceholderLabel.isHidden = true
        diffPlaceholderLabel.text = nil
    }

}

struct RateViewItem {
    let currencyValue: CurrencyValue
    let diff: Decimal
    let dimmed: Bool

    var hash: String {
        "\(currencyValue.value)-\(diff)-\(dimmed)"
    }

}
