import UIKit
import SnapKit
import Chart

class MarketMetricView: UIView {
    static let height: CGFloat = 84

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let diffLabel = RateDiffLabel()
    private let chartView = RateChartView()

    init(configuration: ChartConfiguration) {
        super.init(frame: .zero)

        chartView.apply(configuration: configuration)

        backgroundColor = .themeLawrence
        layer.cornerRadius = .cornerRadius4x
        clipsToBounds = true

        addSubview(chartView)
        chartView.snp.makeConstraints { maker in
            maker.trailing.bottom.equalToSuperview().inset(CGFloat.margin12)
            maker.height.equalTo(configuration.mainHeight)
            maker.width.equalTo(72)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview().inset(CGFloat.margin12)
        }

        titleLabel.font = .micro
        titleLabel.textColor = .themeGray

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin8)
        }

        valueLabel.font = .subhead2

        addSubview(diffLabel)
        diffLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
            maker.top.equalTo(valueLabel.snp.bottom).offset(CGFloat.margin8)
        }

        diffLabel.font = .caption
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension MarketMetricView {

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    func set(value: String?, diff: Decimal?) {
        valueLabel.textColor = value == nil ? .themeGray50 : .themeBran
        valueLabel.text = value ?? "n/a".localized

        guard let diffValue = diff else {
            diffLabel.set(value: nil)

            return
        }
        let diff = diffValue

        diffLabel.set(value: diff)
    }

    func clear() {
        valueLabel.text = nil
        diffLabel.clear()
    }

}
