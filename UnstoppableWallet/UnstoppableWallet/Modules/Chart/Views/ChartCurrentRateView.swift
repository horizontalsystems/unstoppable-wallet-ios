import UIKit

class ChartCurrentRateView: UIView {
    private let rateLabel = UILabel()
    private let rateDiffView = RateDiffView()

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(rateLabel)
        rateLabel.font = .headline2
        rateLabel.textColor = .themeOz
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.equalToSuperview()
        }

        rateDiffView.font = .subhead1

        addSubview(rateDiffView)
        rateDiffView.snp.makeConstraints { maker in
            maker.leading.equalTo(rateLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.bottom.equalTo(rateLabel.snp.bottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(rate: String?, diff: Decimal?) {
        rateLabel.text = rate
        rateDiffView.set(value: diff)
    }

}
