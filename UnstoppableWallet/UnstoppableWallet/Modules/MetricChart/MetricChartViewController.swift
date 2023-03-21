import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import SnapKit
import HUD
import Chart
import ComponentKit

class MetricChartViewController: ThemeActionSheetController {
    private let viewModel: MetricChartViewModel
    private let disposeBag = DisposeBag()

    private let bottomSheetTitle: String
    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let poweredByLabel = UILabel()

    /* Chart section */
    private let chartCell: ChartCell
    private let chartRow: StaticRow

    init(title: String, viewModel: MetricChartViewModel, configuration: ChartConfiguration) {
        bottomSheetTitle = title
        self.viewModel = viewModel

        chartCell = ChartCell(viewModel: viewModel, configuration: configuration)

        chartRow = StaticRow(
                cell: chartCell,
                id: "chartView",
                height: chartCell.cellHeight
        )

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(
                image: .local(image: UIImage(named: "chart_2_24")?.withTintColor(.themeJacob)),
                title: bottomSheetTitle,
                viewController: self
        )

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: TextCell.self)

        chartRow.onReady = { [weak chartCell] in chartCell?.onLoad() }

        tableView.buildSections()
        viewModel.start()
    }

    private func reloadTable() {
        tableView.buildSections()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

}

extension MetricChartViewController {

    private var chartSection: SectionProtocol {
        Section(
                id: "chart",
                footerState: .margin(height: .margin16),
                rows: [chartRow]
        )
    }

}

extension MetricChartViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        [chartSection]
    }

}
