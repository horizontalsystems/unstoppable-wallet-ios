import UIKit

class WalletViewController: UITableViewController {

    private let delegate: IWalletViewDelegate

    private var wallets = [WalletViewItem]()

    private var headerView = UINib(nibName: String(describing: WalletHeaderView.self), bundle: Bundle(for: WalletHeaderView.self)).instantiate(withOwner: nil, options: nil)[0] as? WalletHeaderView

    init(viewDelegate: IWalletViewDelegate) {
        self.delegate = viewDelegate

        super.init(nibName: nil, bundle: nil)

        tabBarItem = UITabBarItem(title: "wallet.tab_bar_item".localized, image: UIImage(named: "balance.tab_bar_item"), tag: 0)
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
        tableView?.registerCell(forClass: WalletCell.self)

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

extension WalletViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.indexPathForSelectedRow == indexPath ? WalletTheme.expandedCellHeight + WalletTheme.cellPadding : WalletTheme.cellHeight + WalletTheme.cellPadding
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: WalletCell.self)) ?? UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? WalletCell {
            cell.bind(item: wallets[indexPath.row], selected: tableView.indexPathForSelectedRow == indexPath, onReceive: { [weak self] in
                self?.onReceive(for: indexPath)
            }, onPay: { [weak self] in
                self?.onPay(for: indexPath)
            })
        }
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? WalletCell {
            cell.unbind()
        }
    }

    func onReceive(for indexPath: IndexPath) {
        delegate.onReceive(for: wallets[indexPath.row].coinValue.coin)
    }

    func onPay(for indexPath: IndexPath) {
        delegate.onPay(for: wallets[indexPath.row].coinValue.coin)
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
        if let cell = tableView?.cellForRow(at: indexPath) as? WalletCell {
            cell.bindView(item: wallets[indexPath.row], selected: tableView?.indexPathForSelectedRow == indexPath, animated: true)
            tableView?.beginUpdates()
            tableView?.endUpdates()
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return WalletTheme.headerHeight
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }

}

extension WalletViewController: IWalletView {

    func set(title: String) {
        self.title = title.localized
    }

    func show(totalBalance: CurrencyValue?) {
        headerView?.bind(amount: totalBalance.flatMap { CurrencyHelper.instance.formattedValue(for: $0) })
    }

    func show(wallets: [WalletViewItem]) {
        self.wallets = wallets
        tableView?.reloadData()
    }

    func show(syncStatus: String) {
        title = "wallet.title".localized + " (\(syncStatus))"
    }

    func didRefresh() {
        refreshControl?.endRefreshing()
    }

}
