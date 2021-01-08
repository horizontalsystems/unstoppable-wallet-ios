import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import HUD

class MarketDefiViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .large48)

    private let marketMetricsCell: MarketMetricsCell
    private let marketTickerCell: MarketTickerCell
    private let marketDefiView = MarketListModule.defiView()

    init() {
        marketMetricsCell = MarketMetricsModule.cell()
        marketTickerCell = MarketTickerModule.cell()

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

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
        sync(isLoading: false)

        marketDefiView.registeringCellClasses.forEach { tableView.registerCell(forClass: $0) }
        marketDefiView.openController = { [weak self] in
            self?.present($0, animated: true)
        }

        subscribe(disposeBag, marketDefiView.sectionUpdatedSignal) { [weak self] in self?.tableView.reload() }
        subscribe(disposeBag, marketDefiView.isLoadingDriver) { [weak self] in self?.sync(isLoading: $0) }

        tableView.buildSections()
    }

    private func sync(isLoading: Bool) {
        guard isLoading && tableView.visibleCells.isEmpty else {
            spinner.isHidden = true
            spinner.stopAnimating()

            return
        }

        spinner.isHidden = false
        spinner.startAnimating()
    }

}

extension MarketDefiViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [marketDefiView.section]
    }

}
