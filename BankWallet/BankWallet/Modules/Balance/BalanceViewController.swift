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
    private let refreshControl = UIRefreshControl()

    private var headerView = BalanceHeaderView(frame: .zero)
    private var indexPathForSelectedRow: IndexPath?

    private var viewItems = [BalanceViewItem]()

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

        refreshControl.tintColor = .appGray50
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        headerView.onStatsSwitch = { [weak self] in
            self?.delegate.onStatsSwitch()
        }

        delegate.viewDidLoad()
    }

    @objc func onRefresh() {
        delegate.refresh()
    }

    @objc private func onSortTypeChange() {
        delegate.onSortTypeChange()
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
            return (indexPathForSelectedRow == indexPath ? BalanceCell.expandedHeight : BalanceCell.height) + CGFloat.margin2x
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
            cell.bind(
                    item: viewItems[indexPath.row],
                    selected: indexPathForSelectedRow == indexPath,
                    onReceive: { [weak self] in
                        self?.delegate.onReceive(index: indexPath.row)
                    },
                    onPay: { [weak self] in
                        self?.delegate.onPay(index: indexPath.row)
                    },
                    onChart: { [weak self] in
                        self?.delegate.onChart(index: indexPath.row)
                    }
            )
        } else if let cell = cell as? BalanceEditCell {
            cell.onTap = { [weak self] in
                self?.delegate.onOpenManageWallets()
            }
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            cell.unbind()
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        bind(at: indexPath, heightChange: true)
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let indexPathForSelectedRow = indexPathForSelectedRow {
            self.indexPathForSelectedRow = nil

            if indexPathForSelectedRow == indexPath {
                tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
                bind(at: indexPath, heightChange: true)
                return nil
            } else {
                bind(at: indexPathForSelectedRow, heightChange: true)
            }
        }

        indexPathForSelectedRow = indexPath
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bind(at: indexPath, heightChange: true)
    }

    func bind(at indexPath: IndexPath, heightChange: Bool = false) {
        if let cell = tableView.cellForRow(at: indexPath) as? BalanceCell {
            cell.bindView(item: viewItems[indexPath.row], selected: indexPathForSelectedRow == indexPath, animated: heightChange)

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
        let changes = diff(old: self.viewItems, new: viewItems)

        self.viewItems = viewItems

        reload(with: changes)
    }

    func set(headerViewItem: BalanceHeaderViewItem) {
        let amount = ValueFormatter.instance.format(currencyValue: headerViewItem.currencyValue)
        headerView.bind(amount: amount, upToDate: headerViewItem.upToDate, statsIsOn: false)
    }

    func didRefresh() {
        refreshControl.endRefreshing()
    }

    func set(statsButtonState: StatsButtonState) {
        headerView.set(statsButtonState: statsButtonState)
    }

    func set(sortIsOn: Bool) {
        if sortIsOn {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Balance Sort Icon"), style: .plain, target: self, action: #selector(onSortTypeChange))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    func showBackupRequired(coin: Coin, predefinedAccountType: IPredefinedAccountType) {
        let controller = BackupRequiredViewController(subtitle: predefinedAccountType.title, text: "receive_alert.not_backed_up_description".localized(predefinedAccountType.title, coin.title), onBackup: { [weak self] in
            self?.delegate.didRequestBackup()
        })

        present(controller, animated: true)
    }

}
