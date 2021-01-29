import UIKit
import RxSwift
import ThemeKit
import SectionsTableView

class MarketOverviewViewController: ThemeViewController {
    private let marketViewModel: MarketViewModel
    private let viewModel: MarketOverviewViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let marketMetricsCell: MarketMetricsCell

    weak var parentNavigationController: UINavigationController?

    private var viewItems = [MarketOverviewViewModel.Section]()

    init(marketViewModel: MarketViewModel, viewModel: MarketOverviewViewModel) {
        self.marketViewModel = marketViewModel
        self.viewModel = viewModel

        marketMetricsCell = MarketMetricsModule.cell()

        super.init()

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.isLoadingDriver) { [weak self] _ in () }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] _ in () }
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

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        tableView.registerHeaderFooter(forClass: MarketSectionHeaderView.self)
        tableView.registerCell(forClass: GB14Cell.self)
        tableView.registerCell(forClass: A2Cell.self)

        tableView.buildSections()
    }

    private func sync(viewItems: [MarketOverviewViewModel.Section]) {
        self.viewItems = viewItems

        tableView.reload()
    }

    private func headerRow(listType: MarketModule.ListType) -> RowProtocol {
        Row<A2Cell>(
                id: "section_header_\(listType.rawValue)",
                height: .heightSingleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .claude)
                    cell.value = "market.top.section.header.see_all".localized
                    cell.valueColor = .themeGray

                    switch listType {
                    case .topGainers:
                        cell.titleImage = UIImage(named: "circle_up_20")
                        cell.title = "market.top.section.header.top_gainers".localized
                    case .topLosers:
                        cell.titleImage = UIImage(named: "circle_down_20")
                        cell.title = "market.top.section.header.top_loosers".localized
                    case .topVolume:
                        cell.titleImage = UIImage(named: "chart_20")
                        cell.title = "market.top.section.header.top_volume".localized
                    }
                },
                action: { [weak self] _ in
                    self?.didTapSeeAll(listType: listType)
                }
        )
    }

    private func row(viewItem: MarketModule.MarketViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<GB14Cell>(
                id: viewItem.coinCode,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    MarketModule.bind(cell: cell, viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                }
        )
    }

    private func onSelect(viewItem: MarketModule.MarketViewItem) {
        let viewController = ChartRouter.module(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: viewItem.coinType))
        parentNavigationController?.pushViewController(viewController, animated: true)
    }

    private func didTapSeeAll(listType: MarketModule.ListType) {
        marketViewModel.handleTapSeeAll(listType: listType)
    }

}

extension MarketOverviewViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()
        sections.append(
            Section(id: "market_metrics", rows: [
                StaticRow(
                    cell: marketMetricsCell,
                    id: "metrics",
                    height: MarketMetricsCell.cellHeight
                )]
            )
        )

        viewItems.forEach { section in
            sections.append(
                Section(id: "header_\(section.listType.rawValue)",
                    footerState: .margin(height: CGFloat.margin12),
                    rows: [
                        headerRow(listType: section.listType)
                ])
            )
            sections.append(
                Section(
                    id: section.listType.rawValue,
                    footerState: .margin(height: CGFloat.margin12),
                    rows: section.viewItems.enumerated().map { (index, item) in
                        row(viewItem: item, isFirst: index == 0, isLast: index == section.viewItems.count - 1)
                })
            )
        }

        return sections
    }

    public func refresh() {
        viewModel.refresh()
    }

}

extension MarketModule.RankColor {

    var color: UIColor {
        switch self {
        case .a: return .themeJacob
        case .b: return .blue
        case .c: return .themeGray
        case .d: return .lightGray
        }
    }

}
