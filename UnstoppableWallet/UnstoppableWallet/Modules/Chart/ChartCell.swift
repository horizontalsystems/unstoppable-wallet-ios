import UIKit
import SnapKit
import RxSwift
import ThemeKit
import ComponentKit
import Chart
import HUD

class ChartCell: UITableViewCell {
    private let viewModel: IChartViewModel & IChartViewTouchDelegate
    private let configuration: ChartConfiguration
    private let disposeBag = DisposeBag()

    private let currentValueWrapper = UIView()
    private let currentValueStackView = UIStackView()
    private let currentValueLabel = UILabel()
    private let currentDiffLabel = DiffLabel()
    private let currentSecondaryTitleLabel = UILabel()
    private let currentSecondaryValueLabel = UILabel()
    private let currentSecondaryDiffLabel = DiffLabel()

    private let chartInfoWrapper = UIStackView()
    private let chartValueLabel = UILabel()
    private let chartDiffLabel = DiffLabel()
    private let chartTimeLabel = UILabel()
    private let chartSecondaryTitleLabel = UILabel()
    private let chartSecondaryValueLabel = UILabel()
    private let chartSecondaryDiffLabel = DiffLabel()

    private let chartView: RateChartView
    private let timePeriodView = FilterView(buttonStyle: .transparent, bottomSeparator: false)
    private let loadingView = HUDActivityView.create(with: .medium24)

    init(viewModel: IChartViewModel & IChartViewTouchDelegate, configuration: ChartConfiguration, isLast: Bool = false) {
        self.viewModel = viewModel
        self.configuration = configuration
        chartView = RateChartView(configuration: configuration)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(currentValueWrapper)
        currentValueWrapper.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(CGFloat.heightDoubleLineCell)
        }

        currentValueWrapper.addSubview(currentValueStackView)
        currentValueStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(CGFloat.margin16)
            make.centerY.equalToSuperview()
        }

        currentValueStackView.alignment = .firstBaseline
        currentValueStackView.spacing = .margin4

        currentValueStackView.addArrangedSubview(currentValueLabel)
        currentValueLabel.font = .title3
        currentValueLabel.textColor = .themeLeah

        currentValueStackView.addArrangedSubview(currentDiffLabel)
        currentDiffLabel.font = .subhead1

        let currentSecondaryStackView = UIStackView()

        currentValueWrapper.addSubview(currentSecondaryStackView)
        currentSecondaryStackView.snp.makeConstraints { make in
            make.leading.equalTo(currentValueStackView.snp.trailing).offset(CGFloat.margin12)
            make.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.centerY.equalToSuperview()
        }

        currentSecondaryStackView.axis = .vertical
        currentSecondaryStackView.alignment = .trailing
        currentSecondaryStackView.spacing = 1

        currentSecondaryStackView.addArrangedSubview(currentSecondaryTitleLabel)
        currentSecondaryTitleLabel.font = .subhead2
        currentSecondaryTitleLabel.textColor = .themeGray

        let currentSecondaryValueStackView = UIStackView()

        currentSecondaryStackView.addArrangedSubview(currentSecondaryValueStackView)
        currentSecondaryValueStackView.spacing = .margin4

        currentSecondaryValueStackView.addArrangedSubview(currentSecondaryValueLabel)
        currentSecondaryValueLabel.font = .subhead2
        currentSecondaryValueLabel.textColor = .themeJacob

        currentSecondaryValueStackView.addArrangedSubview(currentSecondaryDiffLabel)
        currentSecondaryDiffLabel.font = .subhead2

        contentView.addSubview(chartInfoWrapper)
        chartInfoWrapper.snp.makeConstraints { make in
            make.edges.equalTo(currentValueWrapper)
        }

        let chartInfoStackView = UIStackView()

        chartInfoWrapper.addSubview(chartInfoStackView)
        chartInfoStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.centerY.equalToSuperview()
        }

        chartInfoStackView.axis = .vertical
        chartInfoStackView.spacing = 1

        let chartInfoTopStackView = UIStackView()

        chartInfoStackView.addArrangedSubview(chartInfoTopStackView)
        chartInfoTopStackView.spacing = .margin12
        chartInfoTopStackView.alignment = .leading

        let chartInfoValueStackView = UIStackView()

        chartInfoTopStackView.addArrangedSubview(chartInfoValueStackView)
        chartInfoValueStackView.spacing = .margin8
        chartInfoValueStackView.alignment = .center

        chartInfoValueStackView.addArrangedSubview(chartValueLabel)
        chartValueLabel.font = .headline2
        chartValueLabel.textColor = .themeLeah

        chartInfoValueStackView.addArrangedSubview(chartDiffLabel)
        chartDiffLabel.font = .subhead1

        chartInfoTopStackView.addArrangedSubview(chartSecondaryTitleLabel)
        chartSecondaryTitleLabel.textAlignment = .right
        chartSecondaryTitleLabel.font = .subhead2
        chartSecondaryTitleLabel.textColor = .themeGray

        let chartInfoBottomStackView = UIStackView()

        chartInfoStackView.addArrangedSubview(chartInfoBottomStackView)
        chartInfoBottomStackView.spacing = .margin12
        chartInfoBottomStackView.alignment = .trailing

        chartInfoBottomStackView.addArrangedSubview(chartTimeLabel)
        chartTimeLabel.font = .subhead2
        chartTimeLabel.textColor = .themeGray

        let chartInfoSecondaryValueStackView = UIStackView()

        chartInfoBottomStackView.addArrangedSubview(chartInfoSecondaryValueStackView)
        chartInfoSecondaryValueStackView.spacing = .margin4

        chartInfoSecondaryValueStackView.addArrangedSubview(chartSecondaryValueLabel)
        chartSecondaryValueLabel.font = .subhead2

        chartInfoSecondaryValueStackView.addArrangedSubview(chartSecondaryDiffLabel)
        chartSecondaryDiffLabel.font = .subhead2

        contentView.addSubview(chartView)
        chartView.snp.makeConstraints { maker in
            maker.top.equalTo(currentValueWrapper.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(configuration.mainHeight + (configuration.showIndicators ? configuration.indicatorHeight : 0))
        }

        chartView.delegate = viewModel
        chartView.setVolumes(hidden: !configuration.showIndicators)

        contentView.addSubview(timePeriodView)
        timePeriodView.snp.makeConstraints { maker in
            maker.top.equalTo(chartView.snp.bottom).offset(CGFloat.margin8)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightCell48)
        }

        timePeriodView.backgroundColor = .clear
        timePeriodView.reload(filters: viewModel.intervals.map { .item(title: $0) })

        contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.center.equalTo(chartView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var cellHeight: CGFloat {
        .heightDoubleLineCell + configuration.mainHeight + (configuration.showIndicators ? configuration.indicatorHeight : 0) + .margin8 + .heightCell48 + .margin8
    }

    private func syncChart(viewItem: CoinChartViewModel.ViewItem?) {
        guard let viewItem = viewItem else {
            return
        }

        switch viewItem.chartTrend {
        case .neutral:
            chartView.setCurve(colorType: .neutral)
        case .ignore, .up:
            chartView.setCurve(colorType: .up)
        case .down:
            chartView.setCurve(colorType: .down)
        }

        chartView.set(chartData: viewItem.chartData)
        chartView.set(highLimitText: viewItem.maxValue, lowLimitText: viewItem.minValue)
    }

    private func syncChart(selected: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) { [weak self] in
            self?.currentValueWrapper.alpha = selected ? 0 : 1
            self?.chartInfoWrapper.alpha = selected ? 1 : 0
        }
    }

    private func syncChart(selectedViewItem: SelectedPointViewItem?) {
        guard let viewItem = selectedViewItem else {
            return
        }

        chartValueLabel.text = viewItem.value
        chartTimeLabel.text = viewItem.date

        switch viewItem.rightSideMode {
        case .none:
            chartSecondaryTitleLabel.isHidden = true
            chartSecondaryValueLabel.isHidden = true
            chartSecondaryDiffLabel.isHidden = true
        case .volume(let value):
            if let value = value {
                chartSecondaryTitleLabel.isHidden = false
                chartSecondaryValueLabel.isHidden = false

                chartSecondaryTitleLabel.text = "chart.selected.volume".localized
                chartSecondaryValueLabel.text = value
                chartSecondaryValueLabel.textColor = .themeGray
            } else {
                chartSecondaryTitleLabel.isHidden = true
                chartSecondaryValueLabel.isHidden = true
            }

            chartSecondaryDiffLabel.isHidden = true
        case .dominance(let value):
            chartSecondaryTitleLabel.isHidden = false
            chartSecondaryValueLabel.isHidden = false
            chartSecondaryDiffLabel.isHidden = false

            chartSecondaryTitleLabel.text = "BTC Dominance"
            chartSecondaryValueLabel.text = value.flatMap { ValueFormatter.instance.format(percentValue: $0, showSign: false) }
            chartSecondaryValueLabel.textColor = .themeJacob

            chartSecondaryDiffLabel.set(value: 12.3)
        }
    }

    private func syncChart(typeIndex: Int) {
        timePeriodView.select(index: typeIndex)
    }

    private func syncIntervals(typeIndex: Int) {
        timePeriodView.reload(filters: viewModel.intervals.map { .item(title: $0) })
        syncChart(typeIndex: typeIndex)
    }

    private func syncChart(loading: Bool) {
        chartView.isHidden = loading
        loadingView.set(hidden: !loading)

        if loading {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
    }

    private func syncChart(error: String?) { //todo: check logic!
    }

}

extension ChartCell {

    func onLoad() {
        subscribe(disposeBag, viewModel.valueDriver) { [weak self] in self?.currentValueLabel.text = $0 }
        subscribe(disposeBag, viewModel.chartInfoDriver) { [weak self] in
            if let value = $0?.chartDiff {
                self?.currentDiffLabel.isHidden = false
                self?.currentDiffLabel.set(value: value)
            } else {
                self?.currentDiffLabel.isHidden = true
            }
        }

        subscribe(disposeBag, viewModel.pointSelectModeEnabledDriver) { [weak self] in self?.syncChart(selected: $0) }
        subscribe(disposeBag, viewModel.pointSelectedItemDriver) { [weak self] in self?.syncChart(selectedViewItem: $0) }
        subscribe(disposeBag, viewModel.intervalIndexDriver) { [weak self] in self?.syncChart(typeIndex: $0) }
        subscribe(disposeBag, viewModel.intervalsUpdatedWithCurrentIndexDriver) { [weak self] in self?.syncIntervals(typeIndex: $0) }

        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] in self?.syncChart(loading: $0) }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] in self?.syncChart(error: $0) }
        subscribe(disposeBag, viewModel.chartInfoDriver) { [weak self] in self?.syncChart(viewItem: $0) }

        timePeriodView.onSelect = { [weak self] index in
            self?.viewModel.onSelectInterval(at: index)
        }
    }

}
