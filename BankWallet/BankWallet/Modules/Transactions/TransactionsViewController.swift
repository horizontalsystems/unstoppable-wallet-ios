import UIKit
import SnapKit
import ActionSheet
import DeepDiff
import ThemeKit

class TransactionsViewController: ThemeViewController {
    let delegate: ITransactionsViewDelegate

    let tableView = UITableView(frame: .zero, style: .plain)
    private var headerBackgroundTriggerOffset: CGFloat?

    private let cellName = String(describing: TransactionCell.self)

    private let emptyLabel = UILabel()
    private let filterHeaderView = TransactionCurrenciesHeaderView()

    private var items: [TransactionViewItem]?

    init(delegate: ITransactionsViewDelegate) {
        self.delegate = delegate

        super.init()

        tabBarItem = UITabBarItem(title: "transactions.tab_bar_item".localized, image: UIImage(named: "transactions.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "transactions.title".localized

        filterHeaderView.onSelectWallet = { [weak self] wallet in
            self?.delegate.onFilterSelect(wallet: wallet)
        }

        view.addSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView(frame: .zero)

        tableView.registerCell(forClass: TransactionCell.self)
        tableView.estimatedRowHeight = 0
        tableView.delaysContentTouches = false

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(50)
            maker.trailing.equalToSuperview().offset(-50)
        }

        emptyLabel.text = "transactions.empty_text".localized
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .themeGray
        emptyLabel.textAlignment = .center

        delegate.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        headerBackgroundTriggerOffset = headerBackgroundTriggerOffset == nil ? tableView.contentOffset.y : headerBackgroundTriggerOffset
    }

    private func reload(indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let cell = tableView.cellForRow(at: indexPath) as? TransactionCell, let item = items?[indexPath.row] {
                delegate.willShow(item: item)
                cell.bind(item: item, first: indexPath.row == 0, last: tableView.numberOfRows(inSection: indexPath.section) == indexPath.row + 1)
            }
        }
    }

}

extension TransactionsViewController: ITransactionsView {

    func show(filters: [Wallet?]) {
        filterHeaderView.reload(filters: filters)
    }

    func reload(with diff: [Change<TransactionViewItem>], items: [TransactionViewItem], animated: Bool) {
        if (self.items == nil) || !(isViewLoaded && view.window != nil) {
            self.items = items
            tableView.reloadData()
            return
        }

        self.items = items
        let changes = IndexPathConverter().convert(changes: diff, section: 0)

        guard !changes.inserts.isEmpty || !changes.moves.isEmpty || !changes.deletes.isEmpty else {
            reload(indexPaths: changes.replaces)
            return
        }

        tableView.performBatchUpdates({ [weak self] in
            self?.tableView.deleteRows(at: changes.deletes, with: animated ? .fade : .none)
            self?.tableView.insertRows(at: changes.inserts, with: animated ? .fade : .none)
            for movedIndex in changes.moves {
                self?.tableView.moveRow(at: movedIndex.from, to: movedIndex.to)
            }
        }, completion: { [weak self] _ in
            self?.reload(indexPaths: changes.replaces)
        })
    }

}

extension TransactionsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = items?.count ?? 0

        emptyLabel.isHidden = count > 0

        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let items = items, items.count > indexPath.row else {
            return
        }
        if let cell = cell as? TransactionCell {
            delegate.willShow(item: items[indexPath.row])
            cell.bind(item: items[indexPath.row], first: indexPath.row == 0, last: tableView.numberOfRows(inSection: indexPath.section) == indexPath.row + 1)
        }

        if indexPath.row >= self.tableView(tableView, numberOfRowsInSection: 0) - 1 {
            delegate.onBottomReached()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = items?[indexPath.row] {
            delegate.onTransactionClick(item: item)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        filterHeaderView.filters.isEmpty ? 0 : TransactionCurrenciesHeaderView.headerHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        filterHeaderView
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let headerBackgroundTriggerOffset = headerBackgroundTriggerOffset {
            filterHeaderView.backgroundColor = scrollView.contentOffset.y > headerBackgroundTriggerOffset ? .themeNavigationBarBackground : .clear
        }
    }

}
