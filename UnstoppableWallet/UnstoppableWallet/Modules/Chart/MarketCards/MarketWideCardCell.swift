import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import Chart

class MarketWideCardCell: BaseSelectableThemeCell {
    static let height: CGFloat = 152
    static let compactHeight: CGFloat = 80

    private let titleLabel = UILabel()
    private let infoButton = SecondaryCircleButton()
    private let valueLabel = UILabel()
    private let valueInfoLabel = UILabel()
    private let chartView = RateChartView()

    private var onTapInfo: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().inset(CGFloat.margin12)
        }

        titleLabel.font = .subhead2
        titleLabel.textColor = .themeGray

        wrapperView.addSubview(infoButton)
        infoButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin12)
            make.top.equalToSuperview().inset(CGFloat.margin8)
            make.trailing.equalToSuperview().inset(CGFloat.margin12)
        }

        infoButton.set(image: UIImage(named: "circle_information_20"), style: .transparent)
        infoButton.addTarget(self, action: #selector(onTapInfoButton), for: .touchUpInside)

        wrapperView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(CGFloat.margin12)
            make.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin12)
        }

        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.font = .headline1
        valueLabel.textColor = .themeBran

        wrapperView.addSubview(valueInfoLabel)
        valueInfoLabel.snp.makeConstraints { make in
            make.leading.equalTo(valueLabel.snp.trailing).offset(CGFloat.margin8)
            make.trailing.equalToSuperview().inset(CGFloat.margin12)
            make.lastBaseline.equalTo(valueLabel)
        }

        valueInfoLabel.font = .subhead1
        valueInfoLabel.textColor = .themeGray

        wrapperView.addSubview(chartView)
        chartView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
            make.top.equalTo(valueLabel.snp.bottom).offset(CGFloat.margin12)
            make.height.equalTo(60)
        }

        let chartConfiguration = ChartConfiguration.cumulativeChartPreview
        chartConfiguration.mainHeight = 60
        chartView.apply(configuration: chartConfiguration)
        chartView.isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapInfoButton() {
        onTapInfo?()
    }

    func bind(title: String, value: String, valueInfo: String?, chartData: ChartData? = nil, chartColorType: ChartColorType? = nil, onTapInfo: @escaping () -> ()) {
        titleLabel.text = title
        valueLabel.text = value
        valueInfoLabel.text = valueInfo

        if let chartData, let chartColorType {
            chartView.isHidden = false
            chartView.setCurve(colorType: chartColorType)
            chartView.set(chartData: chartData, animated: false)
        } else {
            chartView.isHidden = true
        }

        self.onTapInfo = onTapInfo
    }

}