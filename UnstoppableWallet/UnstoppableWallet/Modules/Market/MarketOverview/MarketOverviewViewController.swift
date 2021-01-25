import UIKit
import RxSwift
import ThemeKit
import SectionsTableView

class MarketOverviewViewController: ThemeViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: MarketOverviewViewModel

    private let tableView = SectionsTableView(style: .grouped)

    private let marketMetricsCell: MarketMetricsCell

    var pushController: ((UIViewController) -> ())?

    private var viewItems = [MarketOverviewViewModel.Section]()

    init(viewModel: MarketOverviewViewModel) {
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
        tableView.registerCell(forClass: GRanked14Cell.self)
        tableView.registerCell(forClass: GRanked14TitledCell.self)

        tableView.buildSections()
    }

    private func sync(viewItems: [MarketOverviewViewModel.Section]) {
        self.viewItems = viewItems

        tableView.reload()
    }

    private func bind<T: UITableViewCell>(cell: T, viewItem: MarketOverviewViewModel.ViewItem) {
        let image = UIImage.image(
                coinCode: viewItem.coinCode,
                blockchainType: viewItem.coinType?.blockchainType
        ) ?? UIImage(named: "placeholder")

        if let cell = cell as? GRanked14Cell {
            cell.set(backgroundStyle: .lawrence)
            cell.leftImage = image
            cell.topText = viewItem.coinName
            cell.bottomText = viewItem.coinCode.uppercased()
            cell.rankText = viewItem.rank.index.description
            cell.priceText = viewItem.rate
            if case let .diff(diff) = viewItem.additionalField {
                cell.diffText = ValueFormatter.instance.format(percentValue: diff)
                cell.diffTextColor = diff.isSignMinus ? .themeLucian : .themeRemus
            } else {
                cell.diffText = nil
            }
        } else if let cell = cell as? GRanked14TitledCell {
            cell.set(backgroundStyle: .lawrence)
            cell.leftImage = image
            cell.topText = viewItem.coinName
            cell.bottomText = viewItem.coinCode.uppercased()
            cell.rankText = viewItem.rank.index.description
            cell.priceText = viewItem.rate
            cell.additionalTitleText = "market.top.volume.title".localized
            if case let .volume(volume) = viewItem.additionalField {
                cell.additionalValueText = volume
            } else {
                cell.additionalValueText = nil
            }
        }
    }

    private func row<T: UITableViewCell>(cellType: T.Type, viewItem: MarketOverviewViewModel.ViewItem) -> RowProtocol {
        Row<T>(
                id: viewItem.coinCode,
                height: .heightDoubleLineCell,
                bind: { [weak self] cell, _ in
                    self?.bind(cell: cell, viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                }
        )
    }

    private func headerState(type: MarketOverviewViewModel.SectionType) -> ViewState<MarketSectionHeaderView> {
        .cellType(hash: "section_header_\(type.rawValue)",
                binder: { view in
                    switch type {
                    case .topGainers:
                        view.set(image: UIImage(named: "circle_up_20"))
                        view.set(title: "market.top.section.header.top_gainers".localized)
                    case .topLoosers:
                        view.set(image: UIImage(named: "circle_down_20"))
                        view.set(title: "market.top.section.header.top_loosers".localized)
                    case .topVolume:
                        view.set(image: UIImage(named: "chart_20"))
                        view.set(title: "market.top.section.header.top_volume".localized)
                    }
                }, dynamicHeight: { containerWidth in
            MarketSectionHeaderView.height
        })
    }

    private func onSelect(viewItem: MarketOverviewViewModel.ViewItem) {
        let viewController = ChartRouter.module(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: viewItem.coinType))
        pushController?(viewController)
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

        sections.append(contentsOf: viewItems.map { section in
            Section(
                id: section.type.rawValue,
                headerState: headerState(type: section.type),
                footerState: .margin(height: CGFloat.margin12),
                rows: section.viewItems.map { viewItem in
                    switch section.type {
                    case .topVolume: return row(cellType: GRanked14TitledCell.self, viewItem: viewItem)
                    default: return row(cellType: GRanked14Cell.self, viewItem: viewItem)
                }
            })
        })

        return sections
    }

    public func refresh() {
        viewModel.refresh()
    }

}
