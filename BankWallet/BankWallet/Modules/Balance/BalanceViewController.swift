import UIKit

class BalanceViewController: UITableViewController {

    private let delegate: IBalanceViewDelegate

    private var items = [BalanceViewItem]()

    private var headerView = UINib(nibName: String(describing: BalanceHeaderView.self), bundle: Bundle(for: BalanceHeaderView.self)).instantiate(withOwner: nil, options: nil)[0] as? BalanceHeaderView

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

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(onRefresh), for: .valueChanged)

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @objc func onRefresh() {
        delegate.refresh()
    }

}

extension BalanceViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.indexPathForSelectedRow == indexPath ? BalanceTheme.expandedCellHeight + BalanceTheme.cellPadding : BalanceTheme.cellHeight + BalanceTheme.cellPadding
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: BalanceCell.self)) ?? UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            cell.bind(item: items[indexPath.row], selected: tableView.indexPathForSelectedRow == indexPath, onReceive: { [weak self] in
                self?.onReceive(for: indexPath)
            }, onPay: { [weak self] in
                self?.onPay(for: indexPath)
            })
        }
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            cell.unbind()
        }
    }

    func onReceive(for indexPath: IndexPath) {
        delegate.onReceive(for: items[indexPath.row].coinValue.coin)
    }

    func onPay(for indexPath: IndexPath) {
        delegate.onPay(for: items[indexPath.row].coinValue.coin)
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        bind(at: indexPath)
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.indexPathForSelectedRow == indexPath {
            tableView.deselectRow(at: indexPath, animated: true)
            bind(at: indexPath)
            return nil
        }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bind(at: indexPath)
    }

    func bind(at indexPath: IndexPath, animated: Bool = false) {
        if let cell = tableView?.cellForRow(at: indexPath) as? BalanceCell {
            cell.bindView(item: items[indexPath.row], selected: tableView?.indexPathForSelectedRow == indexPath, animated: true)
            tableView?.beginUpdates()
            tableView?.endUpdates()
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return BalanceTheme.headerHeight
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
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

    func show(syncStatus: String) {
        title = "balance.title".localized + " (\(syncStatus))"
    }

    func didRefresh() {
        refreshControl?.endRefreshing()
    }

}
