import UIKit
import SnapKit

enum CurrencyFilter: String {
    case all = "all", bitcoin = "bitcoin", bitcoinCahche = "bitcoin_cache", etherium = "etherium"

    static let allValues: [CurrencyFilter] = [.all, .bitcoin, .bitcoinCahche, .etherium]
}
class TransactionsViewController: UITableViewController {

    let delegate: ITransactionsViewDelegate

    private let cellName = String(describing: TransactionCell.self)

    private var items = [TransactionRecordViewItem]()

    private let filterHeaderView = TransactionCurrenciesHeaderView()

    init(delegate: ITransactionsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        tabBarItem = UITabBarItem(title: "transactions.tab_bar_item".localized, image: UIImage(named: "transactions.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "transactions.title".localized

        tableView.backgroundColor = AppTheme.controllerBackground
        tableView.tableFooterView = UIView(frame: .zero)

        tableView.registerCell(forClass: TransactionCell.self)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 0
        tableView.delaysContentTouches = false

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

extension TransactionsViewController: ITransactionsView {

    func show(items: [TransactionRecordViewItem], changeSet: CollectionChangeSet?) {
        self.items = items

//        if let changeSet = changeSet {
//            tableView.beginUpdates()
//
//            if !changeSet.inserted.isEmpty {
//                tableView.insertRows(at: changeSet.inserted.map { IndexPath(row: $0, section: 0) }, with: .automatic)
//            }
//
//            if !changeSet.deleted.isEmpty {
//                tableView.deleteRows(at: changeSet.deleted.map { IndexPath(row: $0, section: 0) }, with: .automatic)
//            }
//
//            if !changeSet.updated.isEmpty {
//                tableView.reloadRows(at: changeSet.updated.map { IndexPath(row: $0, section: 0) }, with: .automatic)
//            }
//
//            tableView.endUpdates()
//        } else {
            tableView.reloadData()
//        }
    }

    func didRefresh() {
        refreshControl?.endRefreshing()
    }

}

extension TransactionsViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TransactionCell {
            cell.bind(item: items[indexPath.row])
        }
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        //stab transaction, only code and hash must be used
        delegate.onTransactionItemClick(transaction: item, coinCode: item.amount.coin.code, txHash: item.transactionHash)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TransactionsTheme.cellHeight
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TransactionsFilterTheme.filterHeaderHeight
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return filterHeaderView
    }

}
