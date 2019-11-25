import UIKit
import SnapKit
import DeepDiff
import ActionSheet

class BalanceViewController: WalletViewController {
    private let numberOfSections = 2
    private let balanceSection = 0
    private let editSection = 1

    private let delegate: IBalanceViewDelegate

    private let tableView = UITableView()
    private let headerView = BalanceHeaderView(frame: .zero)
    private let refreshControl = UIRefreshControl()

    private var viewItems = [BalanceViewItem]()
    private var selectedWallet: Wallet?

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.balance_view", qos: .userInitiated)

    init(viewDelegate: IBalanceViewDelegate) {
        self.delegate = viewDelegate

        super.init()

        tabBarItem = UITabBarItem(title: "balance.tab_bar_item".localized, image: UIImage(named: "balance.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "balance.title".localized

        tableView.backgroundColor = .clear
        tableView.separatorColor = .clear
        tableView.estimatedRowHeight = 0
        tableView.delaysContentTouches = true

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCell(forClass: BalanceCell.self)
        tableView.registerCell(forClass: BalanceEditCell.self)

        refreshControl.tintColor = .appLeah
        refreshControl.alpha = 0.6
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)

        headerView.onTapSortType = { [weak self] in
            self?.delegate.onTapSortType()
        }

        delegate.onLoad()
    }

    @objc func onRefresh() {
        delegate.onTriggerRefresh()
    }

    private func reload(with diff: [Change<BalanceViewItem>]) {
        let changes = IndexPathConverter().convert(changes: diff, section: 0)

        guard changes.deletes.isEmpty && changes.inserts.isEmpty else {
            tableView.reloadData()
            return
        }

        var updateIndexes = changes.moves.reduce([Int]()) {
            var updates = $0
            updates.append($1.from.row)
            updates.append($1.to.row)
            return updates
        }
        updateIndexes.append(contentsOf: changes.replaces.map { $0.row })

        updateIndexes.forEach {
            bind(at: IndexPath(row: $0, section: balanceSection))
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl
    }

    private func bind(cell: BalanceCell, viewItem: BalanceViewItem, animated: Bool = false) {
        cell.bind(
                item: viewItem,
                selected: viewItem.wallet == selectedWallet,
                animated: animated,
                onReceive: { [weak self] in
                    self?.delegate.onTapReceive(viewItem: viewItem)
                },
                onPay: { [weak self] in
                    self?.delegate.onTapPay(viewItem: viewItem)
                },
                onChart: { [weak self] in
                    self?.delegate.onTapChart(viewItem: viewItem)
                }
        )
    }

}

extension BalanceViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == balanceSection {
            return viewItems.count
        } else if section == editSection {
            return 1
        }
        return 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == balanceSection {
            return BalanceCell.height(item: viewItems[indexPath.row], selectedWallet: selectedWallet) + .margin2x
        } else if indexPath.section == editSection {
            return BalanceEditCell.height
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == balanceSection {
            return tableView.dequeueReusableCell(withIdentifier: String(describing: BalanceCell.self), for: indexPath)
        } else if indexPath.section == editSection {
            return tableView.dequeueReusableCell(withIdentifier: String(describing: BalanceEditCell.self), for: indexPath)
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            bind(cell: cell, viewItem: viewItems[indexPath.row])
        } else if let cell = cell as? BalanceEditCell {
            cell.onTap = { [weak self] in
                self?.delegate.onTapAddCoin()
            }
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            cell.unbind()
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if selectedWallet == nil {
            selectedWallet = viewItems[indexPath.row].wallet
            bind(at: indexPath, heightChange: true)
        } else if selectedWallet == viewItems[indexPath.row].wallet {
            selectedWallet = nil
            bind(at: indexPath, heightChange: true)
        } else {
            let previousIndex = viewItems.firstIndex(where: { $0.wallet == selectedWallet })
            selectedWallet = viewItems[indexPath.row].wallet

            if let previousIndex = previousIndex {
                bind(at: IndexPath(row: previousIndex, section: balanceSection), heightChange: true)
            }

            bind(at: indexPath, heightChange: true)
        }

        return nil
    }

    func bind(at indexPath: IndexPath, heightChange: Bool = false) {
        if let cell = tableView.cellForRow(at: indexPath) as? BalanceCell {
            bind(cell: cell, viewItem: viewItems[indexPath.row], animated: heightChange)

            if heightChange {
                UIView.animate(withDuration: BalanceCell.animationDuration) {
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == balanceSection {
            return BalanceHeaderView.height + CGFloat.margin2x
        }
        return 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == balanceSection {
            return headerView
        }
        return nil
    }

}

extension BalanceViewController: IBalanceView {

    func set(viewItems: [BalanceViewItem]) {
        queue.async {
            var forceReload = false

            if let selectedWallet = self.selectedWallet {
                var selectedIndexChange = false
                var heightChange = false

                let oldSelectedIndex = self.viewItems.firstIndex(where: { $0.wallet == selectedWallet })
                let newSelectedIndex = viewItems.firstIndex(where: { $0.wallet == selectedWallet })

                selectedIndexChange = newSelectedIndex != oldSelectedIndex

                if !selectedIndexChange, let oldItem = self.viewItems.first(where: { $0.wallet == selectedWallet }), let newItem = viewItems.first(where: { $0.wallet == selectedWallet }) {
                    let oldHeight = BalanceCell.height(item: oldItem, selectedWallet: selectedWallet)
                    let newHeight = BalanceCell.height(item: newItem, selectedWallet: selectedWallet)

                    heightChange = oldHeight != newHeight
                }

                forceReload = selectedIndexChange || heightChange
            }

            if forceReload {
                DispatchQueue.main.sync {
                    self.viewItems = viewItems
                    self.tableView.reloadData()
                }
            } else {
                let changes = diff(old: self.viewItems, new: viewItems)

                DispatchQueue.main.sync {
                    self.viewItems = viewItems
                    self.reload(with: changes)
                }
            }
        }
    }

    func set(headerViewItem: BalanceHeaderViewItem) {
        DispatchQueue.main.async {
            self.headerView.bind(viewItem: headerViewItem)
        }
    }

    func hideRefresh() {
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
        }
    }

    func set(sortIsOn: Bool) {
        DispatchQueue.main.async {
            self.headerView.setSortButton(hidden: !sortIsOn)
        }
    }

    func showSortType(selectedSortType: BalanceSortType) {
        let sortTypes = BalanceSortType.allCases

        let alertController = AlertViewController(
                header: "balance.sort.header".localized,
                rows: sortTypes.map { sortType in
                    AlertRow(text: sortType.title, selected: sortType == selectedSortType)
                }
        ) { [weak self] selectedIndex in
            self?.delegate.onSelect(sortType: sortTypes[selectedIndex])
        }

        present(alertController, animated: true)
    }

    func showBackupRequired(coin: Coin, predefinedAccountType: PredefinedAccountType) {
        DispatchQueue.main.async {
            let controller = BackupRequiredViewController(subtitle: predefinedAccountType.title, text: "receive_alert.not_backed_up_description".localized(predefinedAccountType.title, coin.title), onBackup: { [weak self] in
                self?.delegate.onRequestBackup()
            })

            self.present(controller, animated: true)
        }
    }

}
