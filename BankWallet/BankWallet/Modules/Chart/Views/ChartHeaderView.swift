import UIKit
import Chart
import SnapKit

class ChartHeaderView: UIView {
    private static let currentRateHeight: CGFloat = 20
    private static let chartHeight: CGFloat = 210
    private static let typeSelectTopOffset: CGFloat = 6
    private static let chartTopOffset: CGFloat = 2

    private let currentRateView = ChartCurrentRateView()
    private let typeSelectView = ChartTypeSelectView()
    private let selectedPointInfoView = ChartPointInfoView()
    private let chartView: ChartRateView

    var onSelectIndex: ((Int) -> ())?

    init(configuration: ChartConfiguration, delegate: IChartIndicatorDelegate) {
        chartView = ChartRateView(configuration: configuration, delegate: delegate)

        super.init(frame: .zero)

        addSubview(currentRateView)
        addSubview(typeSelectView)
        addSubview(chartView)
        addSubview(selectedPointInfoView)

        currentRateView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalToSuperview()
            maker.height.equalTo(ChartHeaderView.currentRateHeight)
        }

        typeSelectView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(currentRateView.snp.bottom).offset(ChartHeaderView.typeSelectTopOffset)
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }
        typeSelectView.onSelectIndex = { [weak self] index in
            self?.onSelectIndex?(index)
        }

        selectedPointInfoView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(currentRateView.snp.bottom).offset(CGFloat.margin3x)
            maker.height.equalTo(29)
        }
        selectedPointInfoView.isHidden = true

        chartView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(typeSelectView.snp.bottom).offset(ChartHeaderView.chartTopOffset)
            maker.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: ChartViewItem) {
        currentRateView.bind(rate: viewItem.currentRate, diff: viewItem.diff)
        typeSelectView.select(index: viewItem.selectedIndex)

        switch viewItem.chartInfoStatus {
        case .loading: chartView.showProcess()
        case .failed: chartView.showError()
        case .completed(let data): chartView.bind(gridIntervalType: data.gridIntervalType, data: data.points, start: data.startTimestamp, end: data.endTimestamp, animated: true)
        }
    }

    func bind(titles: [String]) {
        typeSelectView.reload(titles: titles)
    }

    func showSelected(date: String, time: String?, value: String?, volume: String?) {
        selectedPointInfoView.bind(date: date, time: time, price: value, volume: volume)
        selectedPointInfoView.isHidden = false
        typeSelectView.isHidden = true
    }

    func hideSelected() {
        selectedPointInfoView.isHidden = true
        typeSelectView.isHidden = false
    }

}

extension ChartHeaderView {

    static var viewHeight: CGFloat {
        ChartHeaderView.currentRateHeight + ChartHeaderView.typeSelectTopOffset + .heightSingleLineCell + ChartHeaderView.chartTopOffset + ChartHeaderView.chartHeight
    }

}
