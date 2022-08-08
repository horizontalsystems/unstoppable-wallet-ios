import UIKit
import RxSwift
import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit
import HUD

class MarketDiscoveryViewController: ThemeSearchViewController {
    private let viewModel: MarketDiscoveryViewModel
    private let disposeBag = DisposeBag()

    private let headerView: MarketSingleSortHeaderView
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let tableView = SectionsTableView(style: .grouped)

    private let notFoundPlaceholder = PlaceholderView(layoutType: .keyboard)

    private var discoveryViewItems = [MarketDiscoveryViewModel.DiscoveryViewItem]()
    private var searchViewItems = [MarketDiscoveryViewModel.SearchViewItem]()

    private var isLoaded = false

    init(viewModel: MarketDiscoveryViewModel, sortHeaderViewModel: MarketSingleSortHeaderViewModel) {
        self.viewModel = viewModel
        headerView = MarketSingleSortHeaderView(viewModel: sortHeaderViewModel)

        super.init(scrollViews: [collectionView, tableView])

        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "market_discovery.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "market_discovery.filters".localized, style: .plain, target: self, action: #selector(onTapFilters))

        view.addSubview(headerView)
        headerView.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(MarketSingleSortHeaderView.height)
        }

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        collectionView.backgroundColor = .clear

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MarketDiscoveryCell.self, forCellWithReuseIdentifier: String(describing: MarketDiscoveryCell.self))
        collectionView.register(MarketDiscoveryTitleCell.self, forCellWithReuseIdentifier: String(describing: MarketDiscoveryTitleCell.self))

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.configureSyncError(action: { [weak self] in self?.onRetry() })

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive

        view.addSubview(notFoundPlaceholder)
        notFoundPlaceholder.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        notFoundPlaceholder.image = UIImage(named: "not_found_48")
        notFoundPlaceholder.text = "market_discovery.not_found".localized

        subscribe(disposeBag, viewModel.discoveryViewItemsDriver) { [weak self] in self?.sync(discoveryViewItems: $0) }
        subscribe(disposeBag, viewModel.searchViewItemsDriver) { [weak self] in self?.sync(searchViewItems: $0) }
        subscribe(disposeBag, viewModel.discoveryLoadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
            if loading {
                self?.spinner.startAnimating()
            } else {
                self?.spinner.stopAnimating()
            }
        }
        subscribe(disposeBag, viewModel.discoveryErrorDriver) { [weak self] in self?.errorView.isHidden = $0 == nil }

        subscribe(disposeBag, viewModel.favoritedDriver) { HudHelper.instance.show(banner: .addedToWatchlist) }
        subscribe(disposeBag, viewModel.unfavoritedDriver) { HudHelper.instance.show(banner: .removedFromWatchlist) }
        subscribe(disposeBag, viewModel.failDriver) { HudHelper.instance.show(banner: .error(string: "alert.unknown_error".localized)) }

        isLoaded = true
    }

    @objc private func onTapFilters() {
        let viewController = MarketAdvancedSearchModule.viewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func sync(discoveryViewItems: [MarketDiscoveryViewModel.DiscoveryViewItem]?) {
        if let discoveryViewItems = discoveryViewItems {
            self.discoveryViewItems = discoveryViewItems
            collectionView.reloadData()
            collectionView.isHidden = false
            headerView.isHidden = false
        } else {
            collectionView.isHidden = true
            headerView.isHidden = true
        }
    }

    private func sync(searchViewItems: [MarketDiscoveryViewModel.SearchViewItem]?) {
        if let searchViewItems = searchViewItems {
            self.searchViewItems = searchViewItems
            reloadTable()
            tableView.isHidden = false
            notFoundPlaceholder.isHidden = !searchViewItems.isEmpty
        } else {
            tableView.isHidden = true
            notFoundPlaceholder.isHidden = true
        }
    }

    @objc private func onRetry() {
        viewModel.refresh()
    }

    override func onUpdate(filter: String?) {
        viewModel.onUpdate(filter: filter ?? "")
    }

    private func reloadTable() {
        tableView.buildSections()

        if isLoaded {
            tableView.reload()
        }
    }

    private func onSelect(viewItem: MarketDiscoveryViewModel.SearchViewItem) {
        guard let module = CoinPageModule.viewController(coinUid: viewItem.uid) else {
            return
        }

        present(module, animated: true)
    }

    private func rowActions(index: Int) -> [RowAction] {
        let type: RowActionType
        let iconName: String
        let action: (UITableViewCell?) -> ()

        if viewModel.isFavorite(index: index) {
            type = .destructive
            iconName = "star_off_24"
            action = { [weak self] _ in
                self?.viewModel.unfavorite(index: index)
            }
        } else {
            type = .additive
            iconName = "star_24"
            action = { [weak self] _ in
                self?.viewModel.favorite(index: index)
            }
        }

        return [
            RowAction(
                    pattern: .icon(image: UIImage(named: iconName)?.withTintColor(type.iconColor), background: type.backgroundColor),
                    action: action
            )
        ]
    }

}

extension MarketDiscoveryViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        section == 0 ? 1 : discoveryViewItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: indexPath.section == 0 ? MarketDiscoveryTitleCell.self : MarketDiscoveryCell.self), for: indexPath)
    }

}

extension MarketDiscoveryViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? MarketDiscoveryCell {
            cell.set(viewItem: discoveryViewItems[indexPath.item])
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch discoveryViewItems[indexPath.item].type {
        case .topCoins:
            let viewController = MarketTopModule.viewController()
            present(viewController, animated: true)
        case .category(let category):
            let viewController = MarketCategoryModule.viewController(category: category)
            present(viewController, animated: true)
        }
    }

}

extension MarketDiscoveryViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        indexPath.section == 0 ?
                CGSize(width: collectionView.width, height: .heightSingleLineCell) :
                CGSize(width: (collectionView.width - .margin16 * 2 - .margin12) / 2, height: MarketDiscoveryCell.cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        section == 0 ?
                .zero :
                UIEdgeInsets(top: .margin12, left: .margin16, bottom: .margin32, right: .margin16)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        .margin12
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        .margin12
    }

}

extension MarketDiscoveryViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "coins",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: searchViewItems.enumerated().map { index, viewItem in
                        let isLast = index == searchViewItems.count - 1

                        return CellBuilderNew.row(
                                rootElement: .hStack([
                                    .image24 { component in
                                        component.setImage(urlString: viewItem.imageUrl, placeholder: UIImage(named: viewItem.placeholderImageName))
                                    },
                                    .vStackCentered([
                                        .text { component in
                                            component.font = .body
                                            component.textColor = .themeLeah
                                            component.text = viewItem.name
                                        },
                                        .margin(3),
                                        .text { component in
                                            component.font = .subhead2
                                            component.textColor = .themeGray
                                            component.text = viewItem.code
                                        }
                                    ])
                                ]),
                                tableView: tableView,
                                id: "coin_\(viewItem.uid)",
                                hash: "\(viewItem.favorite)",
                                height: .heightDoubleLineCell,
                                autoDeselect: true,
                                rowActionProvider: { [weak self] in self?.rowActions(index: index) ?? [] },
                                bind: { cell in
                                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                                },
                                action: { [weak self] in
                                    self?.onSelect(viewItem: viewItem)
                                }
                        )
                    }
            )
        ]
    }

}
