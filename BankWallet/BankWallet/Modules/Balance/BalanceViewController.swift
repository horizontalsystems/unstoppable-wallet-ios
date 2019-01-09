import UIKit

class BalanceViewController: UITableViewController {
    private let numberOfSections = 2
    private let balanceSection = 0
    private let editSection = 1

    private let delegate: IBalanceViewDelegate

    private var headerView = UINib(nibName: String(describing: BalanceHeaderView.self), bundle: Bundle(for: BalanceHeaderView.self)).instantiate(withOwner: nil, options: nil)[0] as? BalanceHeaderView
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

        tableView.backgroundColor = AppTheme.controllerBackground
        tableView.separatorColor = .clear
        tableView?.estimatedRowHeight = 0
        tableView?.delaysContentTouches = false

        tableView?.registerCell(forClass: BalanceCell.self)
        tableView?.registerCell(forClass: BalanceEditCell.self)

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

}

extension BalanceViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == balanceSection {
            return delegate.itemsCount
        } else if section == editSection {
            return 1
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == balanceSection {
            return indexPathForSelectedRow == indexPath ? BalanceTheme.expandedCellHeight + BalanceTheme.cellPadding : BalanceTheme.cellHeight + BalanceTheme.cellPadding
        } else if indexPath.section == editSection {
            return BalanceTheme.editCellHeight
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == balanceSection {
            return tableView.dequeueReusableCell(withIdentifier: String(describing: BalanceCell.self), for: indexPath)
        } else if indexPath.section == editSection {
            return tableView.dequeueReusableCell(withIdentifier: String(describing: BalanceEditCell.self), for: indexPath)
        }
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            cell.bind(item: delegate.viewItem(at: indexPath.row), selected: indexPathForSelectedRow == indexPath, onRefresh: { [weak self] in
                self?.delegate.onRefresh(index: indexPath.row)
            }, onReceive: { [weak self] in
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

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            cell.unbind()
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        bind(at: indexPath)
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let indexPathForSelectedRow = indexPathForSelectedRow {
            self.indexPathForSelectedRow = nil
            tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
            bind(at: indexPathForSelectedRow)
            if indexPathForSelectedRow == indexPath {
                return nil
            }
        }
        indexPathForSelectedRow = indexPath
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bind(at: indexPath)
    }

    func bind(at indexPath: IndexPath, animated: Bool = false) {
        if let cell = tableView?.cellForRow(at: indexPath) as? BalanceCell {
            cell.bindView(item: delegate.viewItem(at: indexPath.row), selected: indexPathForSelectedRow == indexPath, animated: true)
            tableView?.beginUpdates()
            tableView?.endUpdates()
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == balanceSection {
            return BalanceTheme.headerHeight
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == balanceSection {
            return headerView
        }
        return nil
    }

}

extension BalanceViewController: IBalanceView {

    func reload() {
        tableView.reloadData()
        updateHeader()
    }

    func updateItem(at index: Int) {
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }

    func updateHeader() {
        let viewItem = delegate.headerViewItem()
        let amount = viewItem.currencyValue.flatMap { ValueFormatter.instance.format(currencyValue: $0) }
        headerView?.bind(amount: amount, upToDate: viewItem.upToDate)
    }

}
