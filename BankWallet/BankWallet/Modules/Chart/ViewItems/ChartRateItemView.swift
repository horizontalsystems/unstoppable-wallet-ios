import UIKit
import UIExtensions
import ActionSheet
import HUD
import SnapKit

class ChartRateItemView: BaseActionItemView {
    private var chartView: ChartView?
    private let processSpinner = HUDProgressView(
            strokeLineWidth: ChartRateTheme.spinnerLineWidth,
            radius: ChartRateTheme.customProgressRadius,
            strokeColor: ChartRateTheme.spinnerLineColor
    )
    private let errorLabel = UILabel()

    override var item: ChartRateItem? { return _item as? ChartRateItem }

    override func initView() {
        super.initView()

        guard let item = item else {
            return
        }

        let chartView = ChartView(configuration: item.chartConfiguration, indicatorDelegate: item.indicatorDelegate)
        self.chartView = chartView
        addSubview(chartView)
        chartView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.left.equalToSuperview().offset(ChartRateTheme.margin)
            maker.right.equalToSuperview()
            maker.height.equalTo(ChartRateTheme.chartViewHeight)
        }

        addSubview(processSpinner)
        processSpinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(ChartRateTheme.customProgressRadius * 2 + ChartRateTheme.spinnerLineWidth)
        }
        processSpinner.isHidden = true

        addSubview(errorLabel)
        errorLabel.contentMode = .center
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.font = ChartRateTheme.chartErrorFont
        errorLabel.textColor = ChartRateTheme.chartErrorColor
        errorLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.equalToSuperview().inset(ChartRateTheme.chartErrorMargin)
        }
        item.bind = { [weak self] type, points, animated in
            self?.showChart()
            self?.chartView?.set(chartType: type, data: points, animated: animated)
        }
        item.showSpinner = { [weak self] in
            self?.showSpinner()
        }
        item.hideSpinner = { [weak self] in
            self?.processSpinner.isHidden = true
            self?.processSpinner.stopAnimating()
        }
        item.showError = { [weak self] error in
            self?.errorLabel.text = error
            self?.showError()
        }
    }

    private func showSpinner() {
        processSpinner.isHidden = false
        processSpinner.startAnimating()

        errorLabel.isHidden = true
        chartView?.isHidden = true
    }

    private func showChart() {
        chartView?.isHidden = false
        errorLabel.isHidden = true
    }

    private func showError() {
        errorLabel.isHidden = false
        chartView?.isHidden = true
    }

}
