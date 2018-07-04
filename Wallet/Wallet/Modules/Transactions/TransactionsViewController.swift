import UIKit
import SnapKit

enum CurrencyFilter: String {
    case all = "all", bitcoin = "bitcoin", bitcoinCahche = "bitcoin_cache", etherium = "etherium"

    static let allValues: [CurrencyFilter] = [.all, .bitcoin, .bitcoinCahche, .etherium]
}
class TransactionsViewController: UIViewController {

    let delegate: ITransactionsViewDelegate

    private let cellName = String(describing: TransactionRecordCell.self)

    private var items = [TransactionRecordViewItem]()
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

        title = "transactions.title".localized

        tableView.backgroundColor = .clear

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)

        tableView.register(UINib(nibName: cellName, bundle: nil), forCellReuseIdentifier: cellName)

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
        if let cell = cell as? TransactionRecordCell {
            cell.bind(item: items[indexPath.row])
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TransactionsFilterTheme.filterHeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return filterHeaderView
    }

}
