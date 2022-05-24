import UIKit
import SnapKit
import Chart
import ThemeKit
import ComponentKit

class ChartPreviewView: UIView {
    class func viewHeight() -> CGFloat { ChartConfiguration.chartPreview.mainHeight + 2 * .margin12 }

    let stackView = UIStackView()
    private let chartView = RateChartView()
    private let button = ThemeButton()

    var onTap: (() -> ())? {
        didSet {
            button.isUserInteractionEnabled = onTap != nil
        }
    }

    var alreadyHasData: Bool = false

    required init(configuration: ChartConfiguration? = nil) {
        super.init(frame: .zero)

        backgroundColor = .themeLawrence
        layer.cornerRadius = .cornerRadius12
        clipsToBounds = true

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview().inset(CGFloat.margin12)
        }

        stackView.distribution = .equalSpacing
        stackView.axis = .vertical
        stackView.spacing = .margin8

        if let configuration = configuration {
            chartView.apply(configuration: configuration)
        }

        stackView.addArrangedSubview(chartView)
        chartView.snp.makeConstraints { maker in
            if let mainHeight = configuration?.mainHeight {
                maker.height.equalTo(mainHeight)
            }
        }

        chartView.isUserInteractionEnabled = false

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        button.isUserInteractionEnabled = false

        updateUI()
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

    func set(configuration: ChartConfiguration) {
        chartView.apply(configuration: configuration)
        chartView.snp.remakeConstraints { maker in
            maker.top.equalTo(stackView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin12)
            maker.height.equalTo(configuration.mainHeight)
        }
    }

    func set(viewItem: ViewItem) {
        let colorType: ChartColorType
        switch viewItem.trend {
        case .neutral: colorType = .neutral
        case .up: colorType = .up
        case .down: colorType = .down
        }

        chartView.setCurve(colorType: colorType)
        if let chartData = viewItem.data {
            chartView.set(chartData: chartData, animated: alreadyHasData)
            alreadyHasData = true
        } else {
            alreadyHasData = false
            // clear
        }
    }

    func clear() {
        alreadyHasData = false
    }

}

extension ChartPreviewView {

    class ViewItem {
        let data: ChartData?
        let trend: MovementTrend

        init(data: ChartData?, trend: MovementTrend) {
            self.data = data
            self.trend = trend
        }

    }

}
