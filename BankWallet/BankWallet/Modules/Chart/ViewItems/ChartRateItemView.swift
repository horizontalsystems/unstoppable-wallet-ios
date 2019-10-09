import UIKit
import UIExtensions
import ActionSheet
import HUD
import SnapKit

class ChartRateItemView: BaseActionItemView {
    private static let spinnerRadius: CGFloat = 11
    private static let spinnerLineWidth: CGFloat = 3

    private var chartView: ChartView?
    private let processSpinner = HUDProgressView(
            strokeLineWidth: ChartRateItemView.spinnerLineWidth,
            radius: ChartRateItemView.spinnerRadius,
            strokeColor: .appOz
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
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview()
            maker.height.equalTo(210)
        }

        addSubview(processSpinner)
        processSpinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(ChartRateItemView.spinnerRadius * 2 + ChartRateItemView.spinnerLineWidth)
        }
        processSpinner.isHidden = true

        addSubview(errorLabel)
        errorLabel.contentMode = .center
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.font = .appSubhead1
        errorLabel.textColor = .cryptoGray
        errorLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.equalToSuperview().inset(CGFloat.margin6x)
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
