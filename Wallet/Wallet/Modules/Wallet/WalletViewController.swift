import UIKit

class WalletViewController: UIViewController {

    let delegate: IWalletViewDelegate

    @IBOutlet weak var tableView: UITableView?

    var wallets = [WalletBalanceViewItem]() {
        didSet {
            wallets.append(contentsOf: [
                //test stab
                WalletBalanceViewItem(coinValue: CoinValue(coin: Bitcoin(), value: 0.004), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 5000), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 20)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: BitcoinCash(), value: 0.2), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 600), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 120)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: Ethereum(), value: 15.3), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 200), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 520)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: Bitcoin(), value: 0.004), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 5000), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 20)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: BitcoinCash(), value: 0.2), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 600), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 120)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: Ethereum(), value: 15.3), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 200), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 520)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: Bitcoin(), value: 0.004), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 5000), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 20)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: BitcoinCash(), value: 0.2), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 600), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 120)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: Ethereum(), value: 15.3), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 200), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 520)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: Bitcoin(), value: 0.004), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 5000), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 20)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: BitcoinCash(), value: 0.2), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 600), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 120)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: Ethereum(), value: 15.3), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 200), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 520)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: Bitcoin(), value: 0.004), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 5000), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 20)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: BitcoinCash(), value: 0.2), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 600), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 120)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: Ethereum(), value: 15.3), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 200), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 520)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: Bitcoin(), value: 0.004), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 5000), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 20)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: BitcoinCash(), value: 0.2), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 600), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 120)),
                WalletBalanceViewItem(coinValue: CoinValue(coin: Ethereum(), value: 15.3), exchangeValue: CurrencyValue(currency: DollarCurrency(), value: 200), currencyValue: CurrencyValue(currency: DollarCurrency(), value: 520))
            ])
        }
    }

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
        wallets = []
        super.viewDidLoad()

        title = "wallet.title".localized

        delegate.viewDidLoad()

        tableView?.estimatedRowHeight = 0
        tableView?.delaysContentTouches = false
        tableView?.registerCell(forClass: WalletCell.self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
                self?.onReceive(for: indexPath)
            }, onPay: { [weak self] in
                self?.onPay(for: indexPath)
            })
        }
    }

    func onReceive(for indexPath: IndexPath) {
        delegate.onReceive(for: indexPath.row)
    }

    func onPay(for indexPath: IndexPath) {
        delegate.onPay(for: indexPath.row)
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

    func show(syncStatus: String) {
        title = "wallet.title".localized + " (\(syncStatus))"
    }

}
