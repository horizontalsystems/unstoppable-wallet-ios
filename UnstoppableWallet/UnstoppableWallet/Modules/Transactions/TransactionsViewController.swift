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
    private var allLoaded = true
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.reset".localized, style: .plain, target: self, action: #selector(onTapReset))

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
        tableView.registerCell(forClass: SpinnerCell.self)
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

        subscribe(disposeBag, viewModel.typeFilterIndexDriver) { [weak self] index in
            self?.typeFiltersView.select(index: index)
        }
        subscribe(disposeBag, viewModel.viewDataDriver) { [weak self] in self?.handle(viewData: $0) }
        subscribe(disposeBag, viewModel.viewStatusDriver) { [weak self] in self?.sync(viewStatus: $0) }
        subscribe(disposeBag, viewModel.resetEnabledDriver) { [weak self] in
            self?.navigationItem.leftBarButtonItem?.isEnabled = $0
        }

        loaded = true
    }

    @objc private func onTapReset() {
        viewModel.onTapReset()
    }

    private func itemClicked(item: TransactionsViewModel.ViewItem) {
        if let record = viewModel.record(uid: item.uid) {
            guard let module = TransactionInfoModule.instance(transactionRecord: record) else {
                return
            }

            present(ThemeNavigationController(rootViewController: module), animated: true)
        }
    }

    private func color(valueType: TransactionsViewModel.ValueType) -> UIColor {
        switch valueType {
        case .incoming: return .themeRemus
        case .outgoing: return .themeLucian
        case .neutral: return .themeLeah
        case .secondary: return .themeGray
        }
    }

    private func handle(viewData: TransactionsViewModel.ViewData) {
        sectionViewItems = viewData.sectionViewItems

        if let allLoaded = viewData.allLoaded {
            self.allLoaded = allLoaded
        }

        guard loaded else {
            return
        }

        if let updateInfo = viewData.updateInfo {
//            print("Update Item: \(updateInfo.sectionIndex)-\(updateInfo.index)")
            let indexPath = IndexPath(row: updateInfo.index, section: updateInfo.sectionIndex)

            if let cell = tableView.cellForRow(at: indexPath) as? BaseThemeCell {
                cell.bind(rootElement: rootElement(viewItem: sectionViewItems[updateInfo.sectionIndex].viewItems[updateInfo.index]))
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

    private func rootElement(viewItem: TransactionsViewModel.ViewItem) -> CellBuilderNew.CellElement {
        .hStack([
            .transactionImage { component in
                component.set(progress: viewItem.progress)

                switch viewItem.iconType {
                case .icon(let imageUrl, let placeholderImageName):
                    component.setImage(
                            urlString: imageUrl,
                            placeholder: UIImage(named: placeholderImageName)
                    )
                case .localIcon(let imageName):
                    component.set(image: imageName.flatMap { UIImage(named: $0)?.withTintColor(.themeLeah) })
                case let .doubleIcon(frontType, frontUrl, frontPlaceholder, backType, backUrl, backPlaceholder):
                    component.setDoubleImage(
                            frontType: frontType,
                            frontUrl: frontUrl,
                            frontPlaceholder: UIImage(named: frontPlaceholder),
                            backType: backType,
                            backUrl: backUrl,
                            backPlaceholder: UIImage(named: backPlaceholder)
                    )
                case .failedIcon:
                    component.set(image: UIImage(named: "warning_2_20")?.withTintColor(.themeLucian))
                }
            },
            .margin(6),
            .vStackCentered([
                .hStack([
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.setContentCompressionResistancePriority(.required, for: .horizontal)
                        component.text = viewItem.title
                    },
                    .text { [weak self] component in
                        if let primaryValue = viewItem.primaryValue, !primaryValue.text.isEmpty {
                            component.isHidden = false
                            component.font = .body
                            component.textColor = self?.color(valueType: primaryValue.type) ?? .themeLeah
                            component.textAlignment = .right
                            component.lineBreakMode = .byTruncatingMiddle
                            component.text = primaryValue.text
                        } else {
                            component.isHidden = true
                        }
                    },
                    .margin8,
                    .image20 { component in
                        component.isHidden = !viewItem.sentToSelf
                        component.imageView.image = UIImage(named: "arrow_return_20")?.withTintColor(.themeGray)
                    },
                    .margin(6),
                    .image20 { component in
                        if let locked = viewItem.locked {
                            component.imageView.image = locked ? UIImage(named: "lock_20")?.withTintColor(.themeGray) : UIImage(named: "unlock_20")?.withTintColor(.themeGray)
                            component.isHidden = false
                        } else {
                            component.isHidden = true
                        }
                    }
                ]),
                .margin(3),
                .hStack([
                    .text { component in
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.setContentCompressionResistancePriority(.required, for: .horizontal)
                        component.text = viewItem.subTitle
                    },
                    .text { [weak self] component in
                        if let secondaryValue = viewItem.secondaryValue, !secondaryValue.text.isEmpty {
                            component.isHidden = false
                            component.font = .subhead2
                            component.textColor = self?.color(valueType: secondaryValue.type) ?? .themeLeah
                            component.textAlignment = .right
                            component.lineBreakMode = .byTruncatingMiddle
                            component.text = secondaryValue.text
                        } else {
                            component.isHidden = true
                        }
                    }
                ])
            ])
        ])
    }

}

extension TransactionsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sectionViewItems.count + (allLoaded ? 0 : 1)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < sectionViewItems.count {
            return sectionViewItems[section].viewItems.count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < sectionViewItems.count {
            return CellBuilderNew.preparedCell(
                    tableView: tableView,
                    indexPath: indexPath,
                    selectable: true,
                    rootElement: rootElement(viewItem: sectionViewItems[indexPath.section].viewItems[indexPath.row]),
                    layoutMargins: UIEdgeInsets(top: 0, left: .margin6, bottom: 0, right: .margin16)
            )
        } else {
            return tableView.dequeueReusableCell(withIdentifier: String(describing: SpinnerCell.self), for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section < sectionViewItems.count {
            let viewItem = sectionViewItems[indexPath.section].viewItems[indexPath.row]

            if let cell = cell as? BaseThemeCell {
                cell.set(backgroundStyle: .transparent, isFirst: indexPath.row != 0, isLast: true)
                cell.bind(rootElement: rootElement(viewItem: viewItem))
            }

            viewModel.onDisplay(sectionIndex: indexPath.section, index: indexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section < sectionViewItems.count {
            tableView.deselectRow(at: indexPath, animated: true)
            itemClicked(item: sectionViewItems[indexPath.section].viewItems[indexPath.row])
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        .heightDoubleLineCell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section < sectionViewItems.count ? .heightSingleLineCell : 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section < sectionViewItems.count {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: TransactionDateHeaderView.self))
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? TransactionDateHeaderView else {
            return
        }

        view.text = sectionViewItems[section].title
    }

}
