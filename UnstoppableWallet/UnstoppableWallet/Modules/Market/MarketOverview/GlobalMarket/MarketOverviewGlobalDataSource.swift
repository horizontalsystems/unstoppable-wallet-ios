import UIKit
import RxSwift
import RxCocoa
import SectionsTableView
import Chart
import ComponentKit

class MarketOverviewGlobalDataSource {
    private let viewModel: MarketOverviewGlobalViewModel
    weak var presentDelegate: IPresentDelegate?
    private let disposeBag = DisposeBag()

    private let marketMetricsCell: MarketOverviewMetricsCell
    private let marketMetricsRow: StaticRow

    private let viewItemRelay = BehaviorRelay<MarketOverviewGlobalViewModel.GlobalMarketViewItem?>(value: nil)

    init(viewModel: MarketOverviewGlobalViewModel, presentDelegate: IPresentDelegate) {
        self.viewModel = viewModel
        self.presentDelegate = presentDelegate

        marketMetricsCell = MarketOverviewMetricsCell(chartConfiguration: ChartConfiguration.chartPreview, presentDelegate: presentDelegate)
        marketMetricsRow = StaticRow(
                cell: marketMetricsCell,
                id: "metrics",
                height: MarketOverviewMetricsCell.cellHeight
        )

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] viewItem in
            self?.viewItemRelay.accept(viewItem)
        }
    }

}

extension MarketOverviewGlobalDataSource: IMarketOverviewDataSource {

    var isReady: Bool {
        viewItemRelay.value != nil
    }

    var updateObservable: Observable<()> {
        viewItemRelay.map { _ in () }
    }

    func sections(tableView: UITableView) -> [SectionProtocol] {
        guard let viewItem = viewItemRelay.value else {
            return []
        }

        marketMetricsRow.onReady = { [weak self] in
            self?.marketMetricsCell.set(viewItem: viewItem)
        }

        return [
            Section(
                    id: "market_metrics",
                    rows: [marketMetricsRow]
            )
        ]
    }

}
