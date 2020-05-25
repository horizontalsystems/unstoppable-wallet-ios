import UIKit
import SnapKit
import Chart
import HUD

class ChartRateView: UIView {
    private static let spinnerRadius: CGFloat = 11
    private static let spinnerLineWidth: CGFloat = 3

    private var chartView: ChartView?
    private let processSpinner = HUDProgressView(
            strokeLineWidth: ChartRateView.spinnerLineWidth,
            radius: ChartRateView.spinnerRadius,
            strokeColor: .themeOz
    )
    private let errorLabel = UILabel()

    init(configuration: ChartConfiguration, delegate: IChartIndicatorDelegate) {
        super.init(frame: .zero)

        backgroundColor = .clear
        let chartView = ChartView(configuration: configuration, gridIntervalType: GridIntervalConverter.convert(chartType: .day), indicatorDelegate: delegate)
        self.chartView = chartView
        addSubview(chartView)
        chartView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        addSubview(processSpinner)
        processSpinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(ChartRateView.spinnerRadius * 2 + ChartRateView.spinnerLineWidth)
        }
        processSpinner.isHidden = true

        addSubview(errorLabel)
        errorLabel.contentMode = .center
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.font = .subhead1
        errorLabel.textColor = .themeGray
        errorLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.equalToSuperview().inset(CGFloat.margin6x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func spinner(hide: Bool) {
        processSpinner.isHidden = hide
        if hide {
            processSpinner.stopAnimating()
        } else {
            processSpinner.startAnimating()
        }
    }

    func bind(gridIntervalType: GridIntervalType, data: [ChartPoint], start: TimeInterval, end: TimeInterval, animated: Bool) {
        chartView?.set(gridIntervalType: gridIntervalType, data: data, start: start, end: end, animated: animated)
        showChart()
    }

    func showProcess() {
        spinner(hide: false)

        errorLabel.isHidden = true
        chartView?.isHidden = true
    }

    func showChart() {
        spinner(hide: true)

        chartView?.isHidden = false
        errorLabel.isHidden = true
    }

    func showError() {
        spinner(hide: true)

        errorLabel.isHidden = false
        chartView?.isHidden = true
    }

}
