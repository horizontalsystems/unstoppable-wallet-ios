import UIKit
import SnapKit

enum CurrencyFilter: String {
    case all = "all", bitcoin = "bitcoin", bitcoinCahche = "bitcoin_cache", etherium = "etherium"

    static let allValues: [CurrencyFilter] = [.all, .bitcoin, .bitcoinCahche, .etherium]
}
class TransactionsViewController: UIViewController {

    let delegate: ITransactionsViewDelegate

    private let cellName = String(describing: TransactionCell.self)

    private var items = [TransactionRecordViewItem]() {
        didSet {
            let items2 = [TransactionRecordViewItem(transactionHash: "3A4SF6K6N2DA7SD8KJ4FN3A4SR7OJAS3V45K3J4BS7A7VK34J3B", amount: CoinValue(coin: Bitcoin(), value: 3.2), fee: CoinValue(coin: Bitcoin(), value: 0.00000402), from: "23SA3D4LJ24FH245B2L6A46D4S23F6H34B6KLJBF", to: "FBJLK6B43H6F32S4D64A6L2B542HF42JL4D3AS32", incoming: true, blockHeight: 124, date: Date(timeIntervalSinceNow: -40000), status: .success, confirmations: 3),
                          TransactionRecordViewItem(transactionHash: "3A4SF6K6N2DA7SD8KJ4FN3A4SR7OJAS3V45K3J4BS7A7VK34J3B", amount: CoinValue(coin: Bitcoin(), value: 3.2), fee: CoinValue(coin: Bitcoin(), value: 0.00020002), from: "23SA3D4LJ24FH245B2L6A46D4S23F6H34B6KLJBF", to: "FBJLK6B43H6F32S4D64A6L2B542HF42JL4D3AS32", incoming: false, blockHeight: 124, date: Date(timeIntervalSinceNow: -40000), status: .success, confirmations: 3)]
            items.append(contentsOf: items2)
        }
    }
    private let tableView = UITableView(frame: .zero, style: .plain)

    private let filterHeaderView = TransactionCurrenciesHeaderView()

    init(delegate: ITransactionsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: String(describing: TransactionsViewController.self), bundle: nil)

        tabBarItem = UITabBarItem(title: "transactions.tab_bar_item".localized, image: UIImage(named: "transactions.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "transactions.title".localized

        tableView.backgroundColor = .clear

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)

        tableView.registerCell(forClass: TransactionCell.self)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 0
        tableView.delaysContentTouches = false

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

extension TransactionsViewController: ITransactionsView {

    func show(items: [TransactionRecordViewItem], changeSet: CollectionChangeSet?) {
        self.items = items

        if let changeSet = changeSet {
            tableView.beginUpdates()

            if !changeSet.inserted.isEmpty {
                tableView.insertRows(at: changeSet.inserted.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            }

            if !changeSet.deleted.isEmpty {
                tableView.deleteRows(at: changeSet.deleted.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            }

            if !changeSet.updated.isEmpty {
                tableView.reloadRows(at: changeSet.updated.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            }

            tableView.endUpdates()
        } else {
            tableView.reloadData()
        }
    }

}

extension TransactionsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TransactionCell {
            cell.bind(item: items[indexPath.row])
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        //stab transaction, only code and hash must be used
        delegate.onTransactionItemClick(transaction: item, coinCode: item.amount.coin.code, txHash: item.transactionHash)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TransactionsTheme.cellHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TransactionsFilterTheme.filterHeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return filterHeaderView
    }

}
