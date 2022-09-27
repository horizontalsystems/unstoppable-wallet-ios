import UIKit
import SnapKit
import Chart
import ThemeKit
import ComponentKit

class MarketCardView: UIView {
    static let height: CGFloat = 109

    let stackView = UIStackView()
    private let titleView = TextComponent()
    private let valueView = TextComponent()

    private let descriptionStackView = UIStackView()
    private let descriptionWrapper = UIView()
    private let descriptionView = TextComponent()

    private let chartView = RateChartView()
    private let button = UIButton()

    private var alreadyHasData: Bool = false

    var onTap: (() -> ())? {
        didSet {
            button.isUserInteractionEnabled = onTap != nil
        }
    }

    required init() {
        super.init(frame: .zero)

        backgroundColor = .themeLawrence
        layer.cornerRadius = .cornerRadius12
        layer.cornerCurve = .continuous
        clipsToBounds = true

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        button.isUserInteractionEnabled = false

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview().inset(CGFloat.margin12)
        }

        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = .margin12
        stackView.isUserInteractionEnabled = false

        stackView.addArrangedSubview(titleView)
        stackView.addArrangedSubview(valueView)
        stackView.addArrangedSubview(descriptionStackView)

        stackView.setCustomSpacing(.margin4, after: valueView)

        descriptionStackView.distribution = .fill
        descriptionStackView.axis = .horizontal
        descriptionStackView.spacing = .margin4
        descriptionStackView.isUserInteractionEnabled = false

        descriptionStackView.addArrangedSubview(descriptionWrapper)
        descriptionStackView.addArrangedSubview(chartView)
        descriptionWrapper.snp.makeConstraints { maker in
            maker.height.equalTo(CGFloat.margin24)
        }

        descriptionWrapper.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
        }

        titleView.font = .caption
        valueView.font = .headline1
        descriptionView.font = .subhead1

        titleView.textColor = .themeGray
        valueView.textColor = .themeBran
        descriptionView.textColor = .themeGray

        descriptionView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        descriptionView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateUI() {
        button.setBackgroundColor(color: .themeLawrencePressed, forState: .highlighted)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateUI()
    }

    @objc private func didTapButton() {
        onTap?()
    }

    var title: String? {
        get { titleView.text }
        set { titleView.text = newValue }
    }

    var value: String? {
        get { valueView.text }
        set {
            valueView.text = newValue
            valueView.textColor = newValue == nil ? .themeGray50 : .themeBran
        }
    }

    var descriptionText: String? {
        get { descriptionView.text }
        set { descriptionView.text = newValue }
    }

    var descriptionColor: UIColor! {
        get { descriptionView.textColor}
        set { descriptionView.textColor = newValue }
    }

    func set(chartData data: ChartData?, trend: MovementTrend?) {
        chartView.isHidden = data == nil
        guard let data = data, let trend = trend else {
            alreadyHasData = false
            return
        }

        chartView.apply(configuration: ChartConfiguration.chartPreview)

        let colorType: ChartColorType
        switch trend {
        case .neutral: colorType = .neutral
        case .up: colorType = .up
        case .down: colorType = .down
        }

        chartView.setCurve(colorType: colorType)
        chartView.set(chartData: data, animated: alreadyHasData)
        alreadyHasData = true
    }

    func set(viewItem: ViewItem) {
        title = viewItem.title
        value = viewItem.value
        descriptionText = viewItem.description
        descriptionColor = viewItem.descriptionColor ?? .themeGray

        set(chartData: viewItem.chartData, trend: viewItem.movementTrend)
    }
}

extension MarketCardView {

    class ViewItem {
        let title: String?
        let value: String?
        let description: String?
        let descriptionColor: UIColor?
        let chartData: ChartData?
        let movementTrend: MovementTrend?

        init(title: String?, value: String?, description: String?, descriptionColor: UIColor? = nil, chartData: ChartData? = nil, movementTrend: MovementTrend? = nil) {
            self.title = title
            self.value = value
            self.description = description
            self.descriptionColor = descriptionColor

            self.chartData = chartData
            self.movementTrend = movementTrend
        }

    }

}

