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

    private let headerView: TransactionsHeaderView
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = PlaceholderView()
    private let typeFiltersView = FilterHeaderView(buttonStyle: .tab)
    private let syncSpinner = HUDActivityView.create(with: .medium24)

    private var sectionViewItems = [TransactionsViewModel.SectionViewItem]()
    private var loaded = false

    init(viewModel: TransactionsViewModel) {
        self.viewModel = viewModel
        headerView = TransactionsHeaderView(viewModel: viewModel)

        super.init()

        headerView.viewController = self
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
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
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

        typeFiltersView.reload(filters: viewModel.typeFilterViewItems)

        typeFiltersView.onSelect = { [weak self] index in
            self?.viewModel.onSelectTypeFilter(index: index)
        }

        view.addSubview(headerView)
        headerView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(typeFiltersView.snp.bottom)
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        emptyView.isHidden = true

        let holder = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        holder.addSubview(syncSpinner)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: holder)

        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        subscribe(disposeBag, viewModel.viewDataDriver) { [weak self] in self?.handle(viewData: $0) }
        subscribe(disposeBag, viewModel.viewStatusDriver) { [weak self] in self?.sync(viewStatus: $0) }

        loaded = true
    }

    private func itemClicked(item: TransactionsViewModel.ViewItem) {
        if let record = viewModel.record(uid: item.uid) {
            guard let module = TransactionInfoModule.instance(transactionRecord: record) else {
                return
            }

            present(ThemeNavigationController(rootViewController: module), animated: true)
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

    private func bind(viewItem: TransactionsViewModel.ViewItem, cell: BaseThemeCell) {
        cell.bind(index: 0) { (component: TransactionImageComponent) in
            component.set(progress: viewItem.progress)

            switch viewItem.iconType {
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

            component.title.text = viewItem.title
            component.subtitle.text = viewItem.subTitle
        }

        cell.bind(index: 2) { (component: MultiTextComponent) in
            component.titleSpacingView.isHidden = true
            component.set(style: .m6)
            component.title.set(style: viewItem.primaryValue.map { primaryStyle(valueType: $0.type) } ?? .b2)
            component.subtitle.set(style: viewItem.secondaryValue.map { secondaryStyle(valueType: $0.type) } ?? .d1)

            component.title.text = viewItem.primaryValue?.text ?? " "
            component.title.textAlignment = .right
            component.subtitle.text = viewItem.secondaryValue?.text ?? " "
            component.subtitle.textAlignment = .right

            if viewItem.sentToSelf {
                component.titleImageLeft.imageView.image = UIImage(named: "arrow_return_20")?.withTintColor(.themeGray)
                component.titleImageLeft.isHidden = false
            } else {
                component.titleImageLeft.isHidden = true
            }

            if let locked = viewItem.locked {
                component.titleImageRight.imageView.image = locked ? UIImage(named: "lock_20")?.withTintColor(.themeGray) : UIImage(named: "unlock_20")?.withTintColor(.themeGray)
                component.titleImageRight.isHidden = false
            } else {
                component.titleImageRight.isHidden = true
            }
        }
    }

    private func handle(viewData: TransactionsViewModel.ViewData) {
        sectionViewItems = viewData.sectionViewItems

        guard loaded else {
            return
        }

        if let updateInfo = viewData.updateInfo {
//            print("Update Item: \(updateInfo.sectionIndex)-\(updateInfo.index)")
            let indexPath = IndexPath(row: updateInfo.index, section: updateInfo.sectionIndex)

            if let cell = tableView.cellForRow(at: indexPath) as? BaseThemeCell {
                bind(viewItem: sectionViewItems[updateInfo.sectionIndex].viewItems[updateInfo.index], cell: cell)
            }
        } else {
//            print("RELOAD TABLE VIEW")
            tableView.reloadData()
        }
    }

    private func sync(viewStatus: TransactionsViewModel.ViewStatus) {
        syncSpinner.isHidden = !viewStatus.showProgress

        if viewStatus.showProgress {
            syncSpinner.startAnimating()
        } else {
            syncSpinner.stopAnimating()
        }

        if let messageType = viewStatus.messageType {
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
        let viewItem = sectionViewItems[indexPath.section].viewItems[indexPath.row]

        if let cell = cell as? BaseThemeCell {
            cell.set(backgroundStyle: .transparent, isFirst: indexPath.row != 0, isLast: true)
            bind(viewItem: viewItem, cell: cell)
        }

        viewModel.onDisplay(sectionIndex: indexPath.section, index: indexPath.row)
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
