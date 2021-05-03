import UIKit
import SnapKit

class MarketMetricLargeView: UIView {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()

    private let titleLabel = UILabel()
    private let gradientCircle = GradientPercentCircle()
    private let valueLabel = UILabel()
    private let diffLabel = RateDiffLabel()

    init() {
        super.init(frame: .zero)

        addSubview(gradientCircle)
        gradientCircle.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.width.equalTo(GradientPercentCircle.width)
            maker.height.equalTo(GradientPercentCircle.height)
        }


        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview()
            maker.trailing.equalTo(gradientCircle.snp.leading).offset(CGFloat.margin12)
        }

        titleLabel.font = .caption
        titleLabel.textColor = .themeGray

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin8)
        }

        valueLabel.font = .title3
        valueLabel.textColor = .themeOz
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(diffLabel)
        diffLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(valueLabel.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalTo(gradientCircle.snp.leading).offset(CGFloat.margin12)
            maker.bottom.equalTo(valueLabel.snp.bottom)
        }

        diffLabel.font = .headline2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension MarketMetricLargeView {

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    func set(value: String?, diff: Decimal?) {
        valueLabel.text = value

        guard let diff = diff else {
            diffLabel.set(value: nil)
            gradientCircle.set(value: nil)

            return
        }

        gradientCircle.set(value: 3 * diff.cgFloatValue)

        diffLabel.set(value: diff)
    }

    public func clear() {
        valueLabel.text = nil
        diffLabel.clear()
    }

}
