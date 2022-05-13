import UIKit
import RxSwift
import RxCocoa
import SectionsTableView
import Chart
import ComponentKit

class MarketOverviewGlobalDataSource {
    private let disposeBag = DisposeBag()

    private let viewModel: MarketOverviewGlobalViewModel
    var presentDelegate: IPresentDelegate

    private let marketMetricsCell: MarketOverviewMetricsCell

    init(viewModel: MarketOverviewGlobalViewModel, presentDelegate: IPresentDelegate) {
        self.viewModel = viewModel
        self.presentDelegate = presentDelegate
        marketMetricsCell = MarketOverviewMetricsCell(chartConfiguration: ChartConfiguration.smallChart, presentDelegate: presentDelegate)
    }

}

extension MarketOverviewGlobalDataSource: IMarketOverviewDataSource {

    func sections(tableView: UITableView) -> [SectionProtocol] {
        guard let viewItem = viewModel.viewItem else {
            return []
        }

        marketMetricsCell.set(viewItem: viewItem)

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
