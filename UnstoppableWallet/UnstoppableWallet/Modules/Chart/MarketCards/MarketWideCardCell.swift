import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import Chart

class MarketWideCardCell: BaseSelectableThemeCell {
    private let titleLabel = UILabel()
    private let infoButton = SecondaryCircleButton()
    private let valueLabel = UILabel()
    private let valueInfoLabel = UILabel()
    private var chartView: RateChartView?

    private var onTapInfo: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalToSuperview().inset(CGFloat.margin12)
        }

        titleLabel.font = .subhead2
        titleLabel.textColor = .themeGray

        wrapperView.addSubview(infoButton)
        infoButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin12)
            make.top.equalToSuperview().inset(CGFloat.margin12)
            make.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        infoButton.set(image: UIImage(named: "circle_information_20"), style: .transparent)
        infoButton.addTarget(self, action: #selector(onTapInfoButton), for: .touchUpInside)

        wrapperView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin12)
        }

        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.font = .headline1
        valueLabel.textColor = .themeBran

        wrapperView.addSubview(valueInfoLabel)
        valueInfoLabel.snp.makeConstraints { make in
            make.leading.equalTo(valueLabel.snp.trailing).offset(CGFloat.margin8)
            make.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.lastBaseline.equalTo(valueLabel)
        }

        valueInfoLabel.font = .subhead1
        valueInfoLabel.textColor = .themeGray
    }

    private func showChartView(configuration: ChartConfiguration) {
        chartView?.removeFromSuperview()

        let chartView = RateChartView(configuration: configuration)

        wrapperView.addSubview(chartView)
        chartView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalTo(valueLabel.snp.bottom).offset(CGFloat.margin12)
            make.height.equalTo(60)
        }

        self.chartView = chartView
        chartView.isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapInfoButton() {
        onTapInfo?()
    }

    func bind(title: String, value: String?, valueInfo: String?, chartData: ChartData? = nil, chartTrend: MovementTrend? = nil, chartCurveType: ChartConfiguration.CurveType = .line, onTapInfo: (() -> ())? = nil) {
        titleLabel.text = title
        valueLabel.text = value
        valueInfoLabel.text = value != nil ? valueInfo : nil

        if let chartData, let chartTrend {
            let chartConfiguration: ChartConfiguration
            switch chartCurveType {
            case .line: chartConfiguration = .previewChart
            case .bars: chartConfiguration = .previewBarChart
            }
            showChartView(configuration: chartConfiguration)

            chartView?.setCurve(colorType: chartTrend.chartColorType)
            chartView?.set(chartData: chartData, animated: false)
        } else {
            chartView?.removeFromSuperview()
            chartView = nil
        }

        self.onTapInfo = onTapInfo
        infoButton.isHidden = onTapInfo == nil
    }

}

extension MarketWideCardCell {

    static func height(hasChart: Bool = true, bottomMargin: CGFloat = .margin16) -> CGFloat {
        64 + (hasChart ? 60 + .margin12 : 0) + bottomMargin
    }

}
