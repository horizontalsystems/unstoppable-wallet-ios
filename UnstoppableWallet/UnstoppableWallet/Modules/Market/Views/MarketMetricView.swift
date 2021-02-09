import UIKit
import SnapKit

class MarketMetricView: UIView {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()

    static let width: CGFloat = 78

    private let titleLabel = UILabel()
    private let gradientBar = GradientPercentBar()
    private let valueLabel = UILabel()
    private let diffLabel = RateDiffLabel()

    init() {
        super.init(frame: .zero)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleLabel.font = .micro
        titleLabel.textColor = .themeGray

        addSubview(gradientBar)
        gradientBar.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.height.equalTo(GradientPercentBar.height)
            maker.width.equalTo(GradientPercentBar.width)
            maker.bottom.equalToSuperview()
        }

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(gradientBar.snp.trailing).offset(CGFloat.margin12)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin6)
            maker.trailing.equalToSuperview()
        }

        valueLabel.font = .subhead2

        addSubview(diffLabel)
        diffLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(gradientBar.snp.trailing).offset(CGFloat.margin12)
            maker.top.equalTo(valueLabel.snp.bottom).offset(CGFloat.margin2)
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        diffLabel.font = .caption
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension MarketMetricView {

    public func set(title: String, value: String?, diff: Decimal?) {
        titleLabel.text = title

        valueLabel.textColor = value == nil ? .themeGray50 : .themeBran
        valueLabel.text = value ?? "n/a".localized

        guard let percentDiff = diff else {
            diffLabel.set(value: nil)
            gradientBar.set(value: nil)

            return
        }
        let diff = percentDiff / 100

        gradientBar.set(value: diff)
        diffLabel.set(value: diff)
    }

    public func clear() {
        titleLabel.text = nil
        valueLabel.text = nil
        diffLabel.clear()
    }

}
