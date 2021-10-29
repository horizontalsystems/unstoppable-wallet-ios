//import ThemeKit
//import SnapKit
//import SectionsTableView
//import ComponentKit
//import RxSwift
//import RxCocoa
//import HUD
//
//class CoinTvlRankViewController: ThemeViewController {
//    private let viewModel: CoinTvlRankViewModel
//    private let disposeBag = DisposeBag()
//
//    private let tableView = SectionsTableView(style: .plain)
//    private let headerView = CoinTvlRankHeaderView()
//    private let spinner = HUDActivityView.create(with: .medium24)
//    private let errorView = ErrorView()
//
//    private var viewItems = [CoinTvlRankViewModel.ViewItem]()
//
//    init(viewModel: CoinTvlRankViewModel) {
//        self.viewModel = viewModel
//
//        super.init()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        title = "coin_page.tvl_rank".localized
//
//        view.addSubview(tableView)
//        tableView.snp.makeConstraints { maker in
//            maker.edges.equalToSuperview()
//        }
//
//        tableView.sectionDataSource = self
//
//        tableView.allowsSelection = false
//        tableView.separatorStyle = .none
//        tableView.backgroundColor = .clear
//
//        tableView.registerCell(forClass: G14Cell.self)
//        tableView.registerCell(forClass: BrandFooterCell.self)
//
//        headerView.onTapFilterField = { [weak self] in
//            self?.openFilterSelector()
//        }
//        headerView.onTapSortField = { [weak self] in
//            self?.viewModel.onSwitchSortType()
//        }
//
//        view.addSubview(spinner)
//        spinner.snp.makeConstraints { maker in
//            maker.center.equalToSuperview()
//        }
//
//        view.addSubview(errorView)
//        errorView.snp.makeConstraints { maker in
//            maker.edges.equalToSuperview().inset(CGFloat.margin16)
//        }
//
//        errorView.text = "coin_page.tvl_rank.sync_error".localized
//
//        subscribe(disposeBag, viewModel.filterDriver) { [weak self] in self?.sync(filter: $0) }
//        subscribe(disposeBag, viewModel.sortDescendingDriver) { [weak self] in self?.syncSort(descending: $0) }
//        subscribe(disposeBag, viewModel.stateDriver) { [weak self] in self?.sync(state: $0) }
//    }
//
//    private func sync(filter: String) {
//        headerView.setFilter(title: filter)
//    }
//
//    private func syncSort(descending: Bool) {
//        headerView.setSort(descending: descending)
//    }
//
//    private func sync(state: CoinTvlRankViewModel.State) {
//        viewItems = []
//        spinner.isHidden = true
//        errorView.isHidden = true
//
//        switch state {
//        case .loading:
//            spinner.isHidden = false
//            spinner.startAnimating()
//        case .failed:
//            errorView.isHidden = false
//        case .loaded(let viewItems):
//            self.viewItems = viewItems
//        }
//
//        tableView.reload()
//    }
//
//    private func openFilterSelector() {
//        let alertController = AlertRouter.module(
//                title: "coin_page.tvl_rank.filters".localized,
//                viewItems: viewModel.filterViewItems
//        ) { [weak self] index in
//            self?.viewModel.onSelectFilter(index: index)
//        }
//
//        present(alertController, animated: true)
//    }
//
//}
//
//extension CoinTvlRankViewController: SectionsDataSource {
//
//    private func row(viewItem: CoinTvlRankViewModel.ViewItem, isLast: Bool) -> RowProtocol {
//        Row<G14Cell>(
//                id: viewItem.coinType.id,
//                height: .heightDoubleLineCell,
//                bind: { cell, _ in
//                    cell.set(backgroundStyle: .transparent, isFirst: false, isLast: isLast)
//
//                    cell.leftImage = .image(coinType: viewItem.coinType)
//                    cell.topText = viewItem.coinTitle
//                    cell.bottomText = viewItem.chain
//                    cell.leftBadgeText = viewItem.rank
//
//                    cell.primaryValueText = viewItem.volume
//                    cell.secondaryValueText = ValueFormatter.instance.format(percentValue: viewItem.diff)
//                    cell.secondaryValueTextColor = viewItem.diff.isSignMinus ? .themeLucian : .themeRemus
//                }
//        )
//    }
//
//    private func poweredBySection(text: String) -> SectionProtocol {
//        Section(
//                id: "powered-by",
//                headerState: .marginColor(height: .margin32, color: .clear),
//                rows: [
//                    Row<BrandFooterCell>(
//                            id: "powered-by",
//                            dynamicHeight: { containerWidth in
//                                BrandFooterCell.height(containerWidth: containerWidth, title: text)
//                            },
//                            bind: { cell, _ in
//                                cell.title = text
//                            }
//                    )
//                ]
//        )
//    }
//
//    func buildSections() -> [SectionProtocol] {
//        var sections: [SectionProtocol] = [
//            Section(
//                    id: "main",
//                    headerState: .static(view: headerView, height: CoinTvlRankHeaderView.height),
//                    rows: viewItems.enumerated().map { index, viewItem in
//                        row(viewItem: viewItem, isLast: index == viewItems.count - 1)
//                    }
//            )
//        ]
//
//        if !viewItems.isEmpty {
//            sections.append(poweredBySection(text: "Powered By DefiLlama API"))
//        }
//
//        return sections
//    }
//
//}
