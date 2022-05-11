import UIKit
import RxSwift
import RxCocoa
import SectionsTableView
import Chart
import ComponentKit

class MarketOverviewGlobalDataSource {
    private let disposeBag = DisposeBag()

    weak var tableView: UITableView?
    var status: DataStatus<[SectionProtocol]> = .loading {
        didSet { statusRelay.accept(()) }
    }
    private let statusRelay = PublishRelay<()>()

    private let viewModel: MarketOverviewGlobalViewModel
    var presentDelegate: IPresentDelegate

    private let marketMetricsCell: MarketOverviewMetricsCell

    init(viewModel: MarketOverviewGlobalViewModel, presentDelegate: IPresentDelegate) {
        self.viewModel = viewModel
        self.presentDelegate = presentDelegate
        marketMetricsCell = MarketOverviewMetricsCell(chartConfiguration: ChartConfiguration.smallChart, presentDelegate: presentDelegate)

        subscribe(disposeBag, viewModel.statusDriver) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<MarketOverviewGlobalViewModel.GlobalMarketViewItem>) {
        self.status = status.map { [weak self] globalMarketViewItem in
            self?.marketMetricsCell.set(viewItem: globalMarketViewItem)

            return sections
        }
    }

    private var sections: [SectionProtocol] {
        var sections = [SectionProtocol]()

        let metricsSection = Section(
                id: "market_metrics",
                rows: [
                    StaticRow(
                            cell: marketMetricsCell,
                            id: "metrics",
                            height: MarketOverviewMetricsCell.cellHeight
                    )
                ]
        )

        sections.append(metricsSection)

        return sections
    }

}

extension MarketOverviewGlobalDataSource: IMarketOverviewDataSource {
    var updateDriver: Driver<()> {
        statusRelay.asDriver(onErrorJustReturn: ())
    }

    func refresh() {
        viewModel.refresh()
    }

}
