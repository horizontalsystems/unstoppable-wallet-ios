import UIKit
import SnapKit

class MarketMetricLargeView: UIView {
    private let titleLabel = UILabel()
    private let gradientCircle = GradientPercentCircle()
    private let valueLabel = UILabel()
    private let diffLabel = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleLabel.font = .micro
        titleLabel.textColor = .themeGray

        addSubview(gradientCircle)
        gradientCircle.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin6)
            maker.width.equalTo(GradientPercentBar.width)
            maker.height.equalTo(GradientPercentBar.height)
        }

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(gradientCircle.snp.trailing).offset(CGFloat.margin12)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin6)
            maker.trailing.equalToSuperview()
        }

        valueLabel.font = .subhead2
        valueLabel.textColor = .themeBran

        addSubview(diffLabel)
        diffLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(gradientCircle.snp.trailing).offset(CGFloat.margin12)
            maker.top.equalTo(valueLabel.snp.bottom).offset(CGFloat.margin2)
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        valueLabel.font = .caption
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension MarketMetricLargeView {

    public func set(title: String?, value: String?, diff: Decimal?) {
        titleLabel.text = title
        valueLabel.text = value

        guard let diff = diff else {
            diffLabel.text = nil
            gradientCircle.set(value: nil)

            return
        }

        gradientCircle.set(value: diff.cgFloatValue)
        let sign = diff >= 0 ? "+" : "-"
        let diffString = sign + diff.roundedString(decimal: 2) + "%"

        diffLabel.text = diffString
        diffLabel.textColor = diff >= 0 ? .themeRemus : .themeLucian
    }

}
