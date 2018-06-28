import UIKit

class WalletViewController: UIViewController {

    let delegate: IWalletViewDelegate

    @IBOutlet weak var totalLabel: UILabel?
    @IBOutlet weak var infoLabel: UILabel?

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

extension WalletViewController: IWalletView {

    func show(totalBalance: CurrencyValue) {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        if let formattedString = formatter.string(from: totalBalance.value as NSNumber) {
            totalLabel?.text = formattedString
        }
    }

    func show(walletBalances: [WalletBalanceViewItem]) {
        var info = ""

        for viewModel in walletBalances.reversed() {
            info += "\(viewModel.coinValue.coin.name)\n\(viewModel.currencyValue.currency.symbol)\(viewModel.currencyValue.value)\n\(viewModel.exchangeValue.currency.symbol)\(viewModel.exchangeValue.value)\n\(viewModel.coinValue.value) \(viewModel.coinValue.coin.code)\n\n"
        }

        infoLabel?.text = info
    }

}
