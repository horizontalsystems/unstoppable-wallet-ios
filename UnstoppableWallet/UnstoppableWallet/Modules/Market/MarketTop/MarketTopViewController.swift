import UIKit
import RxSwift
import ThemeKit
import SectionsTableView

class MarketTopView: ThemeViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: MarketTopViewModel

    private let tableView = SectionsTableView(style: .plain)
    private let marketMetricsCell: MarketMetricsCell

    init(viewModel: MarketTopViewModel) {
        self.viewModel = viewModel

        marketMetricsCell = MarketMetricsModule.cell()

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
//        tableView.contentInset = UIEdgeInsets(top: 128, left: 0, bottom: 0, right: 0)

        tableView.buildSections()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { () -> () in
            self.stubCells()
        }
    }

    func stubCells() {
        let metrics = MarketMetrics(
                totalMarketCap: MetricData(value: "$498.61B", diff: -1.2413),
                volume24h: MetricData(value: "$167.84B", diff: -0.1591),
                btcDominance: MetricData(value: "64.09%", diff: -0.691),
                defiCap: MetricData(value: "$16.31B", diff: 0.0291),
                defiTvl: MetricData(value: "$17.5B", diff: 1.2413))

        marketMetricsCell.bind(marketMetrics: metrics)
    }

}

extension MarketTopView: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {

        var rows = [RowProtocol]()
        rows.append(
                StaticRow(
                        cell: marketMetricsCell,
                        id: "metrics",
                        height: MarketMetricsCell.cellHeight

                )
        )

        return [Section(id: "123", rows: rows)]
    }

}
