import UIKit
import SnapKit

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

    init(viewDelegate: IBalanceViewDelegate) {
        self.delegate = viewDelegate

        super.init(nibName: nil, bundle: nil)

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
        tableView.delaysContentTouches = false

        tableView.registerCell(forClass: BalanceCell.self)
        tableView.registerCell(forClass: BalanceEditCell.self)

        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        headerView.onSortDirectionChange = { [weak self] in
            self?.delegate.onSortDirectionChange()
        }
        headerView.onSortTypeChange = { [weak self] in
            self?.delegate.onSortTypeChange()
        }

        delegate.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        headerBackgroundTriggerOffset = headerBackgroundTriggerOffset == nil ? tableView.contentOffset.y : headerBackgroundTriggerOffset
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @objc func onRefresh() {
        delegate.refresh()
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
            cell.bind(item: delegate.viewItem(at: indexPath.row), selected: indexPathForSelectedRow == indexPath, onReceive: { [weak self] in
                self?.delegate.onReceive(index: indexPath.row)
            }, onPay: { [weak self] in
                self?.delegate.onPay(index: indexPath.row)
            })
        } else if let cell = cell as? BalanceEditCell {
            cell.onTap = { [weak self] in
                self?.delegate.onOpenManageCoins()
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
        if let indexPathForSelectedRow = indexPathForSelectedRow, indexPathForSelectedRow == indexPath {
            self.indexPathForSelectedRow = nil
            tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
            bind(at: indexPath, heightChange: true)
            return nil
        }

        indexPathForSelectedRow = indexPath
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bind(at: indexPath, heightChange: true)
    }

    func bind(at indexPath: IndexPath, heightChange: Bool = false) {
        if let cell = tableView.cellForRow(at: indexPath) as? BalanceCell {
            cell.bindView(item: delegate.viewItem(at: indexPath.row), selected: indexPathForSelectedRow == indexPath, animated: heightChange)

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

    func updateItem(at index: Int) {
        bind(at: IndexPath(row: index, section: balanceSection))
    }

    func updateHeader() {
        let viewItem = delegate.headerViewItem()
        let amount = viewItem.currencyValue.flatMap { ValueFormatter.instance.format(currencyValue: $0) }
        headerView.bind(amount: amount, upToDate: viewItem.upToDate)
    }

    func didRefresh() {
        refreshControl.endRefreshing()
    }

    func setSort(isOn: Bool) {
        headerView.sortView.isHidden = !isOn
    }

    func setSortLabel(key: String) {
        headerView.sortLabelButton.setTitle("balance.sort.\(key)".localized, for: .normal)
    }

    func setSortDirection(desc: Bool) {
        headerView.sortDirectionButton.setImage(desc ? UIImage(named: "Sort Direction Down") : UIImage(named: "Sort Direction Up"), for: .normal)
    }

}
