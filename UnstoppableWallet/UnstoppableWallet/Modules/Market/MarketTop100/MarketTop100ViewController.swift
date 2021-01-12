import UIKit
import RxSwift
import ThemeKit
import SectionsTableView

class MarketTop100ViewController: ThemeViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: MarketTop100ViewModel

    private let tableView = SectionsTableView(style: .plain)

    private let marketMetricsCell: MarketMetricsCell
    private let marketTopView = MarketListModule.topView()

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
