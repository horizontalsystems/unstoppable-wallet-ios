import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import HUD

class MarketDiscoveryViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .large48)

    private let marketMetricsCell: MarketMetricsCell
    private let marketTickerCell: MarketTickerCell

    private let viewModel: MarketDiscoveryViewModel

    var pushController: ((UIViewController) -> ())?

    init(viewModel: MarketDiscoveryViewModel) {
        self.viewModel = viewModel

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


        tableView.registerHeaderFooter(forClass: MarketListHeaderView.self)

        tableView.sectionDataSource = self

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
        sync(isLoading: false)

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

extension MarketDiscoveryViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let headerState: ViewState<MarketListHeaderView> = .cellType(hash: "section_header",
                binder: { view in
                    view.set { [weak self] in
                        print("setted new sortItem")
                    }
                }, dynamicHeight: { containerWidth in
            MarketListHeaderView.height
        })

        return [Section(id: "tokens", headerState: headerState, rows: [])]
    }

}
