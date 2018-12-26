import UIKit

class BalanceViewController: UITableViewController {
    let numberOfSections = 2
    let balanceSection = 0
    let editSection = 1

    private let delegate: IBalanceViewDelegate

    private var items = [BalanceViewItem]()

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

        tableView.backgroundColor = AppTheme.controllerBackground
        tableView.separatorColor = .clear
        tableView?.estimatedRowHeight = 0
        tableView?.delaysContentTouches = false
        tableView?.registerCell(forClass: BalanceCell.self)
        tableView?.registerCell(forClass: BalanceEditCell.self)

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

extension BalanceViewController {

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == balanceSection {
            return items.count
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
            return tableView.dequeueReusableCell(withIdentifier: String(describing: BalanceCell.self)) ?? UITableViewCell()
        } else if indexPath.section == editSection {
            return tableView.dequeueReusableCell(withIdentifier: String(describing: BalanceEditCell.self), for: indexPath)
        }
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            cell.bind(item: items[indexPath.row], selected: indexPathForSelectedRow == indexPath, onRefresh: { [weak self] in
                self?.onRefresh(for: indexPath)
            }, onReceive: { [weak self] in
                self?.onReceive(for: indexPath)
            }, onPay: { [weak self] in
                self?.onPay(for: indexPath)
            })
        } else if let cell = cell as? BalanceEditCell {
            cell.onTap = { [weak self] in
                self?.delegate.onOpenManageCoins()
            }
        }
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            cell.unbind()
        }
    }

    private func onRefresh(for indexPath: IndexPath) {
        delegate.onRefresh(for: items[indexPath.row].coinValue.coinCode)
    }

    private func onReceive(for indexPath: IndexPath) {
        delegate.onReceive(for: items[indexPath.row].coinValue.coinCode)
    }

    private func onPay(for indexPath: IndexPath) {
        delegate.onPay(for: items[indexPath.row].coinValue.coinCode)
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
            cell.bindView(item: items[indexPath.row], selected: indexPathForSelectedRow == indexPath, animated: true)
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

    func set(title: String) {
        self.title = title.localized
    }

    func show(totalBalance: CurrencyValue, upToDate: Bool) {
        headerView?.bind(amount: ValueFormatter.instance.format(currencyValue: totalBalance), upToDate: upToDate)
    }

    func show(items: [BalanceViewItem]) {
        self.items = items
        tableView?.reloadData()
    }

}
