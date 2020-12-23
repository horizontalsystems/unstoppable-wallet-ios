import UIKit
import RxSwift
import ThemeKit
import SectionsTableView

class MarketTop100ViewController: ThemeViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: MarketTop100ViewModel

    private let tableView = SectionsTableView(style: .plain)

    private let marketMetricsCell: MarketMetricsCell
    private let marketTopView = MarketTopModule.view()

    init(viewModel: MarketTop100ViewModel) {
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

        marketTopView.registeringCellClasses.forEach { tableView.registerCell(forClass: $0) }
        marketTopView.openController = { [weak self] in
            self?.present($0, animated: true)
        }

        subscribe(disposeBag, marketTopView.sectionUpdatedSignal) { [weak self] in self?.tableView.reload() }

        tableView.buildSections()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { () -> () in
            self.stubCells()
        }
    }

    func stubCells() {
        let metrics = MarketMetricsService.MarketMetrics(
                totalMarketCap: MarketMetricsService.MetricData(value: "$498.61B", diff: -1.2413),
                volume24h: MarketMetricsService.MetricData(value: "$167.84B", diff: -0.1591),
                btcDominance: MarketMetricsService.MetricData(value: "64.09%", diff: -0.691),
                defiCap: MarketMetricsService.MetricData(value: "$16.31B", diff: 0.0291),
                defiTvl: MarketMetricsService.MetricData(value: "$17.5B", diff: 1.2413))

        marketMetricsCell.bind(marketMetrics: metrics)
    }

}

extension MarketTop100ViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {

        var rows = [RowProtocol]()
        rows.append(
                StaticRow(
                        cell: marketMetricsCell,
                        id: "metrics",
                        height: MarketMetricsCell.cellHeight

                )
        )

        return [Section(id: "123", rows: rows), marketTopView.section]
    }

}
