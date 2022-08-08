import UIKit
import SnapKit
import Chart
import ThemeKit
import ComponentKit

class MarketMetricView: UIView {
    static let height: CGFloat = 104

    private let titleLabel = UILabel()
    private let badgeView = BadgeView()
    private let valueLabel = UILabel()
    private let diffLabel = DiffLabel()
    private let chartView = RateChartView()
    private let button = UIButton()

    var onTap: (() -> ())? {
        didSet {
            button.isUserInteractionEnabled = onTap != nil
        }
    }
    
    var alreadyHasData: Bool = false

    init(configuration: ChartConfiguration? = nil) {
        super.init(frame: .zero)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        button.isUserInteractionEnabled = false

        updateUI()

        if let configuration = configuration {
            chartView.apply(configuration: configuration)
        }

        backgroundColor = .themeLawrence
        layer.cornerRadius = .cornerRadius12
        layer.cornerCurve = .continuous
        clipsToBounds = true

        addSubview(chartView)
        chartView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin12)
            if let mainHeight = configuration?.mainHeight {
                maker.height.equalTo(mainHeight)
            }
        }

        chartView.isUserInteractionEnabled = false

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(CGFloat.margin12)
        }

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.font = .caption
        titleLabel.textColor = .themeGray

        addSubview(badgeView)
        badgeView.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview().inset(CGFloat.margin12)
            maker.leading.equalTo(titleLabel.snp.trailing)
            maker.centerY.equalTo(titleLabel.snp.centerY)
        }

        badgeView.set(style: .small)
        badgeView.isHidden = true

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin12)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin8)
        }

        valueLabel.font = .subhead1

        addSubview(diffLabel)
        diffLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin12)
            maker.leading.equalTo(valueLabel.snp.trailing).offset(CGFloat.margin8)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin8)
        }

        diffLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        diffLabel.textAlignment = .right
        diffLabel.font = .subhead1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateUI() {
        button.setBackgroundColor(color: UIColor.themeLawrencePressed, forState: .highlighted)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateUI()
    }

    @objc private func didTapButton() {
        onTap?()
    }

}

extension MarketMetricView {

    func set(configuration: ChartConfiguration) {
        chartView.apply(configuration: configuration)
        chartView.snp.remakeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin12)
            maker.height.equalTo(configuration.mainHeight)
        }
    }

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var badge: String? {
        get { badgeView.text }
        set {
            badgeView.isHidden = (newValue ?? "").isEmpty
            badgeView.text = newValue
        }
    }

    func set(value: String?, diff: Decimal?, chartData: ChartData?, trend: MovementTrend) {
        valueLabel.textColor = value == nil ? .themeGray50 : .themeBran
        valueLabel.text = value ?? "n/a".localized

        guard let diffValue = diff else {
            diffLabel.set(value: nil)

            return
        }
        let diff = diffValue

        diffLabel.set(value: diff)

        let colorType: ChartColorType
        switch trend {
        case .neutral: colorType = .neutral
        case .up: colorType = .up
        case .down: colorType = .down
        }

        chartView.setCurve(colorType: colorType)
        if let chartData = chartData {
            chartView.set(chartData: chartData, animated: alreadyHasData)
            alreadyHasData = true
        } else {
            alreadyHasData = false
            // clear
        }
    }

    func set(value: String?, diff: String, diffColor: UIColor, chartData: ChartData?, trend: MovementTrend) {
        valueLabel.textColor = value == nil ? .themeGray50 : .themeBran
        valueLabel.text = value ?? "n/a".localized

        diffLabel.set(text: diff, color: diffColor)

        let colorType: ChartColorType
        switch trend {
        case .neutral: colorType = .neutral
        case .up: colorType = .up
        case .down: colorType = .down
        }

        chartView.setCurve(colorType: colorType)
        if let chartData = chartData {
            chartView.set(chartData: chartData, animated: alreadyHasData)
            alreadyHasData = true
        } else {
            alreadyHasData = false
            // clear
        }
    }

    func clear() {
        valueLabel.text = nil
        diffLabel.clear()

        alreadyHasData = false
    }

}
