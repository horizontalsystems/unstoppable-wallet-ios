//import SectionsTableView
//import RxSwift
//import RxCocoa
//
//class MarketListView {
//    private let disposeBag = DisposeBag()
//
//    private let viewModel: MarketListViewModel
//    var openController: ((UIViewController) -> ())?
//    var pushController: ((UIViewController) -> ())?
//
//    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
//    private let errorRelay = BehaviorRelay<String?>(value: nil)
//    private let sectionUpdatedRelay = PublishRelay<()>()
//    private var viewItems = [MarketListViewModel.ViewItem]()
//
//    private let headerView = MarketListHeaderView()
//
//    init(viewModel: MarketListViewModel) {
//        self.viewModel = viewModel
//
//        headerView.set(sortingField: viewModel.sortingFieldTitle)
//        headerView.set(sortingFieldAction: { [weak self] in self?.onTapSortingField() })
//        headerView.set(periodAction: { [weak self] in self?.onTapPeriod() })
//
//        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
//        subscribe(disposeBag, viewModel.isLoadingDriver) { [weak self] in self?.isLoadingRelay.accept($0) }
//        subscribe(disposeBag, viewModel.errorDriver) { [weak self] in self?.errorRelay.accept($0) }
//    }
//
//    private func onTapSortingField() {
//        let alertController = AlertRouter.module(
//                title: "market.sort_by".localized,
//                viewItems: viewModel.sortingFields.map { item in
//                    AlertViewItem(
//                            text: item,
//                            selected: item == viewModel.sortingFieldTitle
//                    )
//                }
//        ) { [weak self] index in
//            self?.setSortingField(at: index)
//        }
//
//        openController?(alertController)
//    }
//
//    private func onTapPeriod() {
//        let alertController = AlertRouter.module(
//                title: "market.changes".localized,
//                viewItems: viewModel.periods.map { item in
//                    AlertViewItem(
//                            text: item,
//                            selected: item == viewModel.periodTitle
//                    )
//                }
//        ) { [weak self] index in
//            self?.setPeriod(at: index)
//        }
//
//        openController?(alertController)
//    }
//
//    private func setSortingField(at index: Int) {
//        viewModel.setSortingField(at: index)
//
//        headerView.set(sortingField: viewModel.sortingFieldTitle)
//    }
//
//    private func setPeriod(at index: Int) {
//        viewModel.setPeriod(at: index)
//
//        headerView.set(period: viewModel.periodTitle)
//    }
//
//    private func sync(viewItems: [MarketListViewModel.ViewItem]) {
//        self.viewItems = viewItems
//
//        sectionUpdatedRelay.accept(())
//    }
//
//    private func row(index: Int, viewItem: MarketListViewModel.ViewItem) -> RowProtocol {
//        let last = index == viewItems.count - 1
//
//        return Row<RateTopListCell>(
//                id: "coin_rate_\(index + 1)",
//                hash: viewItem.coinName,
//                height: .heightDoubleLineCell,
//                autoDeselect: true,
//                bind: { cell, _ in
//                    cell.bind(
//                        rank: viewItem.rank,
//                        coinCode: viewItem.coinCode,
//                        coinName: viewItem.coinName,
//                        rate: viewItem.rate,
//                        diff: viewItem.diff,
//                        last: last)
//                },
//                action: { [weak self] _ in
//                    self?.onSelect(viewItem: viewItem)
//                }
//        )
//
//    }
//
//    private func onSelect(viewItem: MarketListViewModel.ViewItem) {
//        let viewController = ChartRouter.module(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: viewItem.coinType))
//        pushController?(viewController)
//    }
//
//}
//
//extension MarketListView {
//
//    var isLoadingDriver: Driver<Bool> {
//        isLoadingRelay.asDriver()
//    }
//
//    var errorDriver: Driver<String?> {
//        errorRelay.asDriver()
//    }
//
//    public var sectionUpdatedSignal: Signal<()> {
//        sectionUpdatedRelay.asSignal()
//    }
//
//    public var registeringCellClasses: [UITableViewCell.Type] {
//        [RateTopListCell.self]
//    }
//
//    public var section: SectionProtocol {
//        Section(
//            id: "market_top_section",
//            headerState: .static(view: headerView, height: .heightSingleLineCell),
//            rows: viewItems.enumerated().map { index, viewItem in
//                row(index: index, viewItem: viewItem)
//            }
//        )
//    }
//
//    public func refresh() {
//        viewModel.refresh()
//    }
//
//}
