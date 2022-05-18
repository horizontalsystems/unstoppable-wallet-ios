import UIKit
import SnapKit
import ActionSheet
import ThemeKit
import HUD
import ComponentKit
import CurrencyKit
import RxSwift

class TransactionsViewController: ThemeViewController {
    private let viewModel: TransactionsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = PlaceholderView()
    private let typeFiltersView = FilterHeaderView(buttonStyle: .tab)
    private let coinFiltersView = MarketDiscoveryFilterHeaderView()
    private let syncSpinner = HUDActivityView.create(with: .medium24)

    private var sectionViewItems = [TransactionsViewModel.SectionViewItem]()

    private var loaded = false

    init(viewModel: TransactionsViewModel) {
        self.viewModel = viewModel

        super.init()

        tabBarItem = UITabBarItem(title: "transactions.tab_bar_item".localized, image: UIImage(named: "filled_transaction_2n_24"), tag: 0)
        navigationItem.largeTitleDisplayMode = .never
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "transactions.title".localized

        view.addSubview(tableView)

        tableView.backgroundColor = .clear
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.estimatedRowHeight = 0
        tableView.delaysContentTouches = false

        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerHeaderFooter(forClass: TransactionDateHeaderView.self)

        view.addSubview(typeFiltersView)
        typeFiltersView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.height.equalTo(FilterHeaderView.height)
        }

        typeFiltersView.onSelect = { [weak self] index in
            self?.viewModel.typeFilterSelected(index: index)
        }

        view.addSubview(coinFiltersView)
        coinFiltersView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(typeFiltersView.snp.bottom)
            maker.height.equalTo(MarketDiscoveryFilterHeaderView.headerHeight)
        }

        coinFiltersView.onSelect = { [weak self] index in
            self?.viewModel.coinFilterSelected(index: index)
        }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.top.equalTo(coinFiltersView.snp.bottom)
            maker.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        let holder = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        holder.addSubview(syncSpinner)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: holder)

        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(coinFiltersView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        subscribe(disposeBag, viewModel.sectionViewItemsDriver) { [weak self] in self?.handle(sectionViewItems: $0) }
        subscribe(disposeBag, viewModel.updatedViewItemSignal) { [weak self] (sectionIndex, rowIndex, item) in self?.update(sectionIndex: sectionIndex, rowIndex: rowIndex, item: item) }
        subscribe(disposeBag, viewModel.typeFiltersDriver) { [weak self] coinFilters in self?.show(typeFilters: coinFilters) }
        subscribe(disposeBag, viewModel.coinFiltersDriver) { [weak self] coinFilters in self?.show(coinFilters: coinFilters) }
        subscribe(disposeBag, viewModel.viewStatusDriver) { [weak self] status in self?.show(status: status) }

        loaded = true
    }

    private func itemClicked(item: TransactionsViewModel.ViewItem) {
        if let item = viewModel.transactionItem(uid: item.uid) {
            guard let module = TransactionInfoModule.instance(transactionRecord: item.record) else {
                return
            }

            present(ThemeNavigationController(rootViewController: module), animated: true)
        }
    }

    private func update(sectionIndex: Int, rowIndex: Int, item: TransactionsViewModel.ViewItem) {
        DispatchQueue.main.async {
            self.sectionViewItems[sectionIndex].viewItems[rowIndex] = item

            let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
            if let cell = self.tableView.cellForRow(at: indexPath) as? BaseThemeCell {
                self.bind(item: item, cell: cell)
            }
        }
    }

    private func primaryStyle(valueType: TransactionsViewModel.ValueType) -> TextComponent.Style {
        switch valueType {
        case .incoming: return .b4
        case .outgoing: return .b5
        case .neutral: return .b2
        case .secondary: return .b1
        }
    }

    private func secondaryStyle(valueType: TransactionsViewModel.ValueType) -> TextComponent.Style {
        switch valueType {
        case .incoming: return .d4
        case .outgoing: return .d5
        case .neutral: return .d2
        case .secondary: return .d1
        }
    }

    private func bind(item: TransactionsViewModel.ViewItem, cell: BaseThemeCell) {
        cell.bind(index: 0) { (component: TransactionImageComponent) in
            component.set(progress: item.progress)

            switch item.iconType {
            case .icon(let imageUrl, let placeholderImageName):
                component.setImage(
                        urlString: imageUrl,
                        placeholder: UIImage(named: placeholderImageName)
                )
            case .localIcon(let imageName):
                component.set(image: imageName.flatMap { UIImage(named: $0)?.withTintColor(.themeLeah) })
            case let .doubleIcon(frontImageUrl, frontPlaceholderImageName, backImageUrl, backPlaceholderImageName):
                component.setDoubleImage(
                        frontUrlString: frontImageUrl,
                        frontPlaceholder: UIImage(named: frontPlaceholderImageName),
                        backUrlString: backImageUrl,
                        backPlaceholder: UIImage(named: backPlaceholderImageName)
                )
            case .failedIcon:
                component.set(image: UIImage(named: "warning_2_20")?.withTintColor(.themeLucian))
            }
        }

        cell.bind(index: 1) { (component: MultiTextComponent) in
            component.set(style: .m1)
            component.title.set(style: .b2)
            component.subtitle.set(style: .d1)

            component.title.text = item.title
            component.subtitle.text = item.subTitle
        }

        cell.bind(index: 2) { (component: MultiTextComponent) in
            component.titleSpacingView.isHidden = true
            component.set(style: .m6)
            component.title.set(style: item.primaryValue.map { primaryStyle(valueType: $0.type) } ?? .b2)
            component.subtitle.set(style: item.secondaryValue.map { secondaryStyle(valueType: $0.type) } ?? .d1)

            component.title.text = item.primaryValue?.text ?? " "
            component.title.textAlignment = .right
            component.subtitle.text = item.secondaryValue?.text ?? " "
            component.subtitle.textAlignment = .right

            if item.sentToSelf {
                component.titleImageLeft.imageView.image = UIImage(named: "arrow_return_20")?.withTintColor(.themeGray)
                component.titleImageLeft.isHidden = false
            } else {
                component.titleImageLeft.isHidden = true
            }

            if let locked = item.locked {
                component.titleImageRight.imageView.image = locked ? UIImage(named: "lock_20")?.withTintColor(.themeGray) : UIImage(named: "unlock_20")?.withTintColor(.themeGray)
                component.titleImageRight.isHidden = false
            } else {
                component.titleImageRight.isHidden = true
            }
        }
    }

    private func rowsBeforeBottom(indexPath: IndexPath) -> Int {
        var section = tableView.numberOfSections
        var count = 0

        while indexPath.section < section {
            section -= 1
            let rowsCount = tableView.numberOfRows(inSection: section)

            if indexPath.section == section {
                return count + rowsCount - (indexPath.row + 1)
            } else {
                count += rowsCount
            }
        }

        return count
    }

    private func handle(sectionViewItems: [TransactionsViewModel.SectionViewItem]) {
        self.sectionViewItems = sectionViewItems

        if loaded {
            tableView.reloadData()
        }
    }

    private func show(status: TransactionsModule.ViewStatus) {
        syncSpinner.isHidden = !status.showProgress

        if status.showProgress {
            syncSpinner.startAnimating()
        } else {
            syncSpinner.stopAnimating()
        }

        if let messageType = status.messageType {
            switch messageType {
            case .syncing:
                emptyView.image = UIImage(named: "clock_48")
                emptyView.text = "transactions.syncing_text".localized
            case .empty:
                emptyView.image = UIImage(named: "outgoing_raw_48")
                emptyView.text = "transactions.empty_text".localized
            }

            emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
        }
    }

    private func show(typeFilters: (filters: [FilterHeaderView.ViewItem], selected: Int)) {
        typeFiltersView.reload(filters: typeFilters.filters)
        typeFiltersView.select(index: typeFilters.selected)
    }

    private func show(coinFilters: (filters: [MarketDiscoveryFilterHeaderView.ViewItem], selected: Int?)) {
        coinFiltersView.set(filters: coinFilters.filters)
        coinFiltersView.setSelected(index: coinFilters.selected)
    }

}

extension TransactionsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sectionViewItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sectionViewItems[section].viewItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        CellBuilder.preparedSelectableCell(tableView: tableView, indexPath: indexPath, elements: [.transactionImage, .margin8, .multiText, .multiText], layoutMargins: UIEdgeInsets(top: 0, left: .margin8, bottom: 0, right: .margin16))
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = sectionViewItems[indexPath.section].viewItems[indexPath.row]

        viewModel.willShow(uid: item.uid)

        if let cell = cell as? BaseThemeCell {
            cell.set(backgroundStyle: .transparent, isFirst: indexPath.row != 0, isLast: true)
            bind(item: item, cell: cell)
        }

        if rowsBeforeBottom(indexPath: indexPath) <= 5 {
            viewModel.bottomReached()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        itemClicked(item: sectionViewItems[indexPath.section].viewItems[indexPath.row])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        .heightDoubleLineCell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .heightSingleLineCell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: TransactionDateHeaderView.self))
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? TransactionDateHeaderView else {
            return
        }

        view.text = sectionViewItems[section].title
    }

}
