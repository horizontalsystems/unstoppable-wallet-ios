import UIKit
import SnapKit
import ActionSheet
import DeepDiff
import ThemeKit
import HUD
import ComponentKit
import CurrencyKit

class TransactionsViewController: ThemeViewController {
    let delegate: ITransactionsViewDelegate

    let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.transactions_view", qos: .userInitiated)
    let differ: IDiffer

    let tableView = UITableView(frame: .zero, style: .plain)

    private let cellName = String(describing: H23Cell.self)

    private let emptyLabel = UILabel()
    private let filterHeaderView = FilterHeaderView()

    private var items: [TransactionViewItem]?

    private let syncSpinner = HUDActivityView.create(with: .medium24)

    init(delegate: ITransactionsViewDelegate, differ: IDiffer) {
        self.delegate = delegate
        self.differ = differ

        super.init()

        tabBarItem = UITabBarItem(title: "transactions.tab_bar_item".localized, image: UIImage(named: "filled_transaction_2n_24"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "transactions.title".localized

        filterHeaderView.onSelect = { [weak self] index in
            self?.delegate.onFilterSelect(index: index)
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

        tableView.registerCell(forClass: H23Cell.self)
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

        let holder = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        holder.addSubview(syncSpinner)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: holder)

        delegate.viewDidLoad()
    }

    private func bind(item: TransactionViewItem, cell: H23Cell) {
        delegate.willShow(item: item)

        var image: UIImage? = nil
        var imageColor: UIColor
        var spinnerProgress: Float? = nil
        var topText: String
        var bottomText: String = ""
        var valueTopText: String = ""
        var valueTopTextColor: UIColor = .themeJacob
        var valueBottomText: String? = nil
        var valueBottomTextColor: UIColor = .themeGray
        var valueLeftIconImage: UIImage? = nil
        var valueRightIconImage: UIImage? = nil

        switch item.type {
        case .incoming(let from, let amount, let lockState, _):
            image = UIImage(named: "arrow_medium_main_down_left_20")
            imageColor = .themeRemus
            topText = "transactions.receive".localized
            bottomText = from.flatMap { "transactions.from".localized($0) } ?? "---"

            if let currencyValueString = item.mainAmountCurrencyString {
                valueTopText = currencyValueString
                valueTopTextColor = .themeRemus
            }

            valueBottomText = amount

            if let lockState = lockState {
                if lockState.locked {
                    valueLeftIconImage = UIImage(named: "lock_20")?.withRenderingMode(.alwaysTemplate)
                } else {
                    valueLeftIconImage = UIImage(named: "unlock_20")?.withRenderingMode(.alwaysTemplate)
                }
                cell.valueLeftIconTinColor = .themeGray
            }

        case .outgoing(let to, let amount, let lockState, _, let sentToSelf):
            image = UIImage(named: "arrow_medium_main_up_right_20")
            imageColor = .themeJacob
            topText = "transactions.send".localized
            bottomText = to.flatMap { "transactions.to".localized($0) } ?? "---"

            if let currencyValueString = item.mainAmountCurrencyString {
                valueTopText = currencyValueString
                valueTopTextColor = .themeJacob
            }

            valueBottomText = amount

            if let lockState = lockState {
                if lockState.locked {
                    valueLeftIconImage = UIImage(named: "lock_20")?.withRenderingMode(.alwaysTemplate)
                } else {
                    valueLeftIconImage = UIImage(named: "unlock_20")?.withRenderingMode(.alwaysTemplate)
                }
                cell.valueLeftIconTinColor = .themeGray
            }

            if sentToSelf {
                valueRightIconImage = UIImage(named: "arrow_medium_main_down_left_20")?.withRenderingMode(.alwaysTemplate)
                cell.valueRightIconTinColor = .themeRemus
            }

        case .approve(let spender, let amount, let isMaxAmount):
            image = UIImage(named: "check_2_20")
            imageColor = .themeLeah
            topText = "transactions.approve".localized
            bottomText = "transactions.from".localized(spender)

            if let currencyValueString = item.mainAmountCurrencyString {
                if isMaxAmount {
                    valueTopText = "∞"
                } else {
                    valueTopText = currencyValueString
                }
                valueTopTextColor = .themeLeah
            }

            if isMaxAmount {
                valueBottomText = "transactions.value.unlimited".localized
            } else {
                valueBottomText = amount
            }

        case .swap(let exchangeAddress, let amountIn, let amountOut, let foreignRecipient):
            image = UIImage(named: "swap_2_20")
            imageColor = .themeLeah
            topText = "transactions.swap".localized
            bottomText = exchangeAddress

            valueTopText = amountIn
            valueTopTextColor = .themeJacob

            valueBottomText = amountOut
            valueBottomTextColor = foreignRecipient ? .themeGray : .themeRemus

        case .contractCall(let contractAddress, let method):
            image = UIImage(named: "unordered_20")
            imageColor = .themeLeah
            topText = method?.uppercased() ?? "transactions.contract_call".localized
            bottomText = contractAddress

        case .contractCreation:
            image = UIImage(named: "unordered_20")
            imageColor = .themeLeah
            topText = "transactions.contract_creation".localized
            bottomText = "---"
        }

        switch item.status {
        case .pending:
            spinnerProgress = 20

        case .processing(let progress):
            spinnerProgress = Float(progress) * 80 / 100 + 20

        case .failed:
            image = UIImage(named: "warning_2_20")
            imageColor = .themeLucian

        default: ()
        }

        cell.leftImage = image?.withRenderingMode(.alwaysTemplate)
        cell.leftImageTintColor = imageColor
        cell.set(spinnerProgress: spinnerProgress)

        cell.topText = topText
        cell.topTextColor = .themeOz
        cell.bottomText = bottomText

        cell.valueTopText = valueTopText
        cell.valueTopTextColor = valueTopTextColor
        cell.valueBottomText = valueBottomText
        cell.valueBottomTextColor = valueBottomTextColor
        
        cell.valueLeftIconImage = valueLeftIconImage
        cell.valueRightIconImage = valueRightIconImage
    }

    private func bind(itemAt indexPath: IndexPath, to cell: UITableViewCell?) {
        guard let items = items, items.count > indexPath.row else {
            return
        }

        let item = items[indexPath.row]
        if let cell = cell as? H23Cell {
            cell.set(backgroundStyle: .claude, isFirst: indexPath.row != 0, isLast: true)
            bind(item: item, cell: cell)
        }

        if indexPath.row >= self.tableView(tableView, numberOfRowsInSection: 0) - 1 {
            delegate.onBottomReached()
        }
    }

    private func reload(indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            bind(itemAt: indexPath, to: tableView.cellForRow(at: indexPath))
        }
    }

    private func reload(with changes: ChangeWithIndexPath, animated: Bool) {
        if !isViewLoaded || view.window == nil {
            tableView.reloadData()
            return
        }

        reload(indexPaths: changes.replaces)

        guard !changes.inserts.isEmpty || !changes.moves.isEmpty || !changes.deletes.isEmpty else {
            return
        }

        tableView.performBatchUpdates({ [weak self] in
            self?.tableView.deleteRows(at: changes.deletes, with: animated ? .fade : .none)
            self?.tableView.insertRows(at: changes.inserts, with: animated ? .fade : .none)
            for movedIndex in changes.moves {
                self?.tableView.moveRow(at: movedIndex.from, to: movedIndex.to)
            }
        })
    }

    private func show(status: TransactionViewStatus) {
        syncSpinner.isHidden = !status.showProgress
        if status.showProgress {
            syncSpinner.startAnimating()
        } else {
            syncSpinner.stopAnimating()
        }

        emptyLabel.isHidden = !status.showMessage
    }

}

extension TransactionsViewController: ITransactionsView {

    func set(status: TransactionViewStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.show(status: status)
        }
    }

    func show(filters: [FilterHeaderView.ViewItem]) {
        filterHeaderView.reload(filters: filters)
    }

    func show(transactions newViewItems: [TransactionViewItem], animated: Bool) {
        queue.async {
            let changes = self.differ.changes(old: self.items ?? [], new: newViewItems, section: 0)
            self.items = newViewItems

            DispatchQueue.main.sync { [weak self] in
                self?.reload(with: changes, animated: animated)
            }
        }
    }

    func showNoTransactions() {
        show(transactions: [], animated: true)
    }

    func reloadTransactions() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

}

extension TransactionsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        bind(itemAt: indexPath, to: cell)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = items?[indexPath.row] {
            delegate.onTransactionClick(item: item)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        .heightDoubleLineCell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        filterHeaderView.headerHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        filterHeaderView
    }

}
