import UIKit

class WalletViewController: UIViewController {

    let delegate: IWalletViewDelegate

    @IBOutlet weak var tableView: UITableView?

    var wallets = [WalletBalanceViewItem]()

    var headerView = UINib(nibName: String(describing: WalletHeaderView.self), bundle: Bundle(for: WalletHeaderView.self)).instantiate(withOwner: nil, options: nil)[0] as? WalletHeaderView

    init(viewDelegate: IWalletViewDelegate) {
        self.delegate = viewDelegate

        super.init(nibName: String(describing: WalletViewController.self), bundle: nil)

        tabBarItem = UITabBarItem(title: "wallet.tab_bar_item".localized, image: UIImage(named: "balance.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Backup", style: .plain, target: self, action: #selector(openBackup))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))

        delegate.viewDidLoad()

        tableView?.estimatedRowHeight = 0
        tableView?.registerCell(forClass: WalletCell.self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @objc func openBackup() {
        present(BackupRouter.module(dismissMode: .dismissSelf), animated: true)
    }

    @objc func refresh() {
    }

}

extension WalletViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.indexPathForSelectedRow == indexPath ? WalletTheme.expandedCellHeight + WalletTheme.cellPadding : WalletTheme.cellHeight + WalletTheme.cellPadding
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: WalletCell.self)) ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? WalletCell {
            cell.bind(balance: wallets[indexPath.row], selected: tableView.indexPathForSelectedRow == indexPath, onReceive: { [weak self] in
                print("onReceive \(self!.wallets[indexPath.row])")
            }, onPay: { [weak self] in
                print("onPay \(self!.wallets[indexPath.row])")
            })
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        bind(at: indexPath)
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.indexPathForSelectedRow == indexPath {
            tableView.deselectRow(at: indexPath, animated: true)
            bind(at: indexPath)
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bind(at: indexPath)
    }

    func bind(at indexPath: IndexPath, animated: Bool = false) {
        if let cell = tableView?.cellForRow(at: indexPath) as? WalletCell {
            cell.bindView(balance: wallets[indexPath.row], selected: tableView?.indexPathForSelectedRow == indexPath, animated: true)
            tableView?.beginUpdates()
            tableView?.endUpdates()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return WalletTheme.headerHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }

}

extension WalletViewController: IWalletView {

    func show(totalBalance: CurrencyValue) {
        headerView?.bind(amount: CurrencyHelper.instance.formattedValue(for: totalBalance))
    }

    func show(walletBalances: [WalletBalanceViewItem]) {
        wallets = walletBalances.reversed()
        tableView?.reloadData()
    }

}
