import UIKit
import SnapKit
import ActionSheet
import DeepDiff

class TransactionsViewController: WalletViewController {
    let delegate: ITransactionsViewDelegate

    let tableView = UITableView(frame: .zero, style: .plain)
    private var headerBackgroundTriggerOffset: CGFloat?

    private let cellName = String(describing: TransactionCell.self)

    private let emptyLabel = UILabel()
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

        filterHeaderView.onSelectCoin = { [weak self] coin in
            self?.delegate.onFilterSelect(coin: coin)
        }

        view.addSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView(frame: .zero)

        tableView.registerCell(forClass: TransactionCell.self)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 0
        tableView.delaysContentTouches = false

        let emptyView = UIView()
        emptyView.backgroundColor = .clear
        tableView.backgroundView = emptyView

        view.layoutIfNeeded()
        emptyLabel.text = "transactions.empty_text".localized
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .cryptoGray
        emptyLabel.textAlignment = .center
        emptyView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(50)
            maker.trailing.equalToSuperview().offset(-50)
        }

        delegate.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate.onViewAppear()
        headerBackgroundTriggerOffset = headerBackgroundTriggerOffset == nil ? tableView.contentOffset.y : headerBackgroundTriggerOffset
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    func bind(at indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? TransactionCell {
            let item = delegate.item(forIndex: indexPath.row)
            cell.bind(item: item, first: indexPath.row == 0, last: tableView.numberOfRows(inSection: indexPath.section) == indexPath.row + 1)
        }
    }

    private func reload(indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            bind(at: indexPath)
        }
    }

}

extension TransactionsViewController: ITransactionsView {

    func show(filters: [Coin?]) {
        filterHeaderView.reload(filters: filters)
    }

    func reload() {
        tableView.reloadData()
    }

    func bindVisible() {
        if let visibleIndexes = (tableView.indexPathsForVisibleRows?.map { return $0.row }) {
            bind(indexes: visibleIndexes)
        }
    }

    func bind(indexes: [Int]) {
        reload(indexPaths: indexes.map { IndexPath(row: $0, section: 0) })
    }

    func reload(with diff: [Change<TransactionItem>]) {
        let changes = IndexPathConverter().convert(changes: diff, section: 0)

        guard !changes.inserts.isEmpty || !changes.moves.isEmpty || !changes.deletes.isEmpty else {
            reload(indexPaths: changes.replaces)
            return
        }

        tableView.performBatchUpdates({ [weak self] in
            self?.tableView.insertRows(at: changes.inserts, with: .fade)
            self?.tableView.deleteRows(at: changes.deletes, with: .fade)
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
        let count = delegate.itemsCount

        emptyLabel.isHidden = count > 0

        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TransactionCell {
            cell.bind(item: delegate.item(forIndex: indexPath.row), first: indexPath.row == 0, last: tableView.numberOfRows(inSection: indexPath.section) == indexPath.row + 1)
        }

        if indexPath.row >= self.tableView(tableView, numberOfRowsInSection: 0) - 1 {
            delegate.onBottomReached()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate.onTransactionItemClick(index: indexPath.row)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TransactionsTheme.cellHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return filterHeaderView.filters.isEmpty ? 0 : TransactionsFilterTheme.filterHeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return filterHeaderView
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let headerBackgroundTriggerOffset = headerBackgroundTriggerOffset {
            filterHeaderView.backgroundColor = scrollView.contentOffset.y > headerBackgroundTriggerOffset ? AppTheme.navigationBarBackgroundColor : .clear
        }
    }

}
