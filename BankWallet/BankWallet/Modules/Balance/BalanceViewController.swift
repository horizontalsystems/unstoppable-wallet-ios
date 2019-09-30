import UIKit
import SnapKit
import DeepDiff
import ActionSheet

class BalanceViewController: WalletViewController {
    private let numberOfSections = 2
    private let balanceSection = 0
    private let editSection = 1
    private var headerBackgroundTriggerOffset: CGFloat?

    let tableView = UITableView()
    let refreshControl = UIRefreshControl()

    private let delegate: IBalanceViewDelegate

    private var headerView = BalanceHeaderView(frame: .zero)
    private var indexPathForSelectedRow: IndexPath?

    private var chartEnabled: Bool = false

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

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorColor = .clear
        tableView.estimatedRowHeight = 0
        tableView.delaysContentTouches = true

        tableView.registerCell(forClass: BalanceCell.self)
        tableView.registerCell(forClass: BalanceEditCell.self)

        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        headerView.onStatsSwitch = { [weak self] in
            self?.delegate.onStatsSwitch()
        }

        delegate.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        headerBackgroundTriggerOffset = headerBackgroundTriggerOffset == nil ? tableView.contentOffset.y : headerBackgroundTriggerOffset
    }

    @objc func onRefresh() {
        delegate.refresh()
    }

    @objc private func onSortTypeChange() {
        delegate.onSortTypeChange()
    }

}

extension BalanceViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == balanceSection {
            return delegate.itemsCount
        } else if section == editSection {
            return 1
        }
        return 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == balanceSection {
            return (indexPathForSelectedRow == indexPath ? BalanceTheme.expandedCellHeight : BalanceTheme.cellHeight) + BalanceTheme.cellPadding
        } else if indexPath.section == editSection {
            return BalanceTheme.editCellHeight
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
            cell.bind(item: delegate.viewItem(at: indexPath.row), isStatModeOn: chartEnabled, selected: indexPathForSelectedRow == indexPath, onReceive: { [weak self] in
                self?.delegate.onReceive(index: indexPath.row)
            }, onPay: { [weak self] in
                self?.delegate.onPay(index: indexPath.row)
            }, onChart: {[weak self] in
                self?.delegate.onChart(index: indexPath.row)
            })
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
            cell.bindView(item: delegate.viewItem(at: indexPath.row), isStatModeOn: chartEnabled, selected: indexPathForSelectedRow == indexPath, animated: heightChange)

            if heightChange {
                UIView.animate(withDuration: BalanceTheme.buttonsAnimationDuration) {
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == balanceSection {
            return BalanceTheme.headerHeight
        }
        return 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == balanceSection {
            return headerView
        }
        return nil
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let headerBackgroundTriggerOffset = headerBackgroundTriggerOffset {
            headerView.backgroundColor = scrollView.contentOffset.y > headerBackgroundTriggerOffset ? AppTheme.navigationBarBackgroundColor : .clear
        }
    }

}

extension BalanceViewController: IBalanceView {

    func reload() {
        tableView.reloadData()
        updateHeader()
    }

    func reload(with diff: [DeepDiff.Change<BalanceItem>]) {
        let changes = IndexPathConverter().convert(changes: diff, section: 0)

        guard changes.deletes.isEmpty || changes.inserts.isEmpty else {
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

    func updateHeader() {
        let viewItem = delegate.headerViewItem()
        let amount = viewItem.currencyValue.flatMap { ValueFormatter.instance.format(currencyValue: $0) }
        headerView.bind(amount: amount, upToDate: viewItem.upToDate, statsIsOn: chartEnabled)
    }

    func didRefresh() {
        refreshControl.endRefreshing()
    }

    func setStatsButton(state: StatsButtonState) {
        switch state {
        case .normal:
            headerView.setStatSwitch(hidden: false)
            chartEnabled = false
        case .hidden:
            headerView.setStatSwitch(hidden: true)
        case .selected:
            headerView.setStatSwitch(hidden: false)
            chartEnabled = true
        }
    }

    func setSort(isOn: Bool) {
        if isOn {
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
