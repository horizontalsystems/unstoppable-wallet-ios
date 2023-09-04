import Combine
import UIKit
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import DeepDiff
import HUD
import MarketKit
import ComponentKit

class WalletTokenListViewController: ThemeSearchViewController {
    private let animationDuration: TimeInterval = 0.2

    private let viewModel: WalletTokenListViewModel
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    private let tableView = UITableView(frame: .zero, style: .plain)

    private let spinner = HUDActivityView.create(with: .medium24)

    private let emptyView = PlaceholderView()
    private let failedView = PlaceholderView()
    private let invalidApiKeyView = PlaceholderView()

    private var viewItems = [BalanceViewItem]()
    private var isLoaded = false

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet_tokens_view_controller", qos: .userInitiated)

    var onSelectWallet: ((Wallet) -> ())?

    init(viewModel: WalletTokenListViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapClose))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.searchController?.searchBar.placeholder = "add_token.coin_name".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false

        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerCell(forClass: WalletTokenCell.self)
        tableView.registerCell(forClass: EmptyCell.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        spinner.startAnimating()

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyView.image = UIImage(named: "empty_wallet_48")
        emptyView.text = viewModel.emptyText

        view.addSubview(failedView)
        failedView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        failedView.image = UIImage(named: "sync_error_48")
        failedView.text = "sync_error".localized
        failedView.addPrimaryButton(
                style: .yellow,
                title: "button.retry".localized,
                target: self,
                action: #selector(onTapRetry)
        )

        view.addSubview(invalidApiKeyView)
        invalidApiKeyView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        invalidApiKeyView.image = UIImage(named: "not_available_48")
        invalidApiKeyView.text = "balance.invalid_api_key".localized

        subscribe(disposeBag, viewModel.noConnectionErrorSignal) { HudHelper.instance.show(banner: .noInternet) }
        subscribe(disposeBag, viewModel.showSyncingSignal) { HudHelper.instance.show(banner: .attention(string: "Wait for synchronization")) }
        subscribe(disposeBag, viewModel.selectWalletSignal) { [weak self] in self?.onSelect(wallet: $0) }
        subscribe(disposeBag, viewModel.openSyncErrorSignal) { [weak self] in self?.openSyncError(wallet: $0, error: $1) }

        viewModel.$state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

        sync(state: viewModel.state)

        isLoaded = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc func onTapClose() {
        dismiss(animated: true)
    }

    @objc private func onTapRetry() {
        // todo
    }

    private func sync(state: WalletTokenListViewModel.State) {
        switch state {
        case .list: navigationItem.searchController?.searchBar.isHidden = false
        default: navigationItem.searchController?.searchBar.isHidden = true
        }
        switch state {
        case .noAccount: emptyView.isHidden = false
        default: emptyView.isHidden = false
        }

        switch state {
        case .loading: spinner.isHidden = false
        default: spinner.isHidden = true
        }

        switch state {
        case .list(let viewItems):
            if isLoaded {
                handle(newViewItems: viewItems)
            } else {
                self.viewItems = viewItems
            }
            tableView.isHidden = false
        default:
            tableView.isHidden = true
        }

        switch state {
        case .empty: emptyView.isHidden = false
        default: emptyView.isHidden = true
        }

        switch state {
        case .syncFailed: failedView.isHidden = false
        default: failedView.isHidden = true
        }

        switch state {
        case .invalidApiKey: invalidApiKeyView.isHidden = false
        default: invalidApiKeyView.isHidden = true
        }
    }

    private func handle(newViewItems: [BalanceViewItem]) {
        let changes = diff(old: viewItems, new: newViewItems)

        guard !changes.isEmpty else {
            return
        }

        if changes.contains(where: {
            if case .insert = $0 { return true }
            if case .delete = $0 { return true }
            return false
        }) {
            viewItems = newViewItems
            tableView.reloadData()
            return
        }

        var updateIndexes = Set<Int>()

        for change in changes {
            switch change {
            case .move(let move):
                updateIndexes.insert(move.fromIndex)
                updateIndexes.insert(move.toIndex)
            case .replace(let replace):
                updateIndexes.insert(replace.index)
            default: ()
            }
        }

        viewItems = newViewItems

        UIView.animate(withDuration: animationDuration) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }

        updateIndexes.forEach {
            if let cell = tableView.cellForRow(at: IndexPath(row: $0, section: 0)) as? WalletTokenCell {
                bind(cell: cell, index: $0, animated: true)
            }
        }
    }

    private func bind(cell: WalletTokenCell, index: Int, animated: Bool = false) {
        let viewItem = viewItems[index]

        cell.set(backgroundStyle: .transparent, isLast: index == viewItems.count - 1)

        cell.bind(
                viewItem: viewItem,
                animated: animated,
                duration: animationDuration,
                onTapError: { [weak self] in
                    self?.viewModel.onTapFailedIcon(element: viewItem.element)
                }
        )
    }

    private func onSelect(wallet: Wallet) {
        onSelectWallet?(wallet)
    }

    private func openSyncError(wallet: Wallet, error: Error) {
        let viewController = BalanceErrorModule.viewController(wallet: wallet, error: error, sourceViewController: navigationController)
        present(viewController, animated: true)
    }

    private func showAccountsLost() {
        let controller = UIAlertController(title: "lost_accounts.warning_title".localized, message: "lost_accounts.warning_message".localized, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "button.ok".localized, style: .default))
        controller.show()
    }

    override func onUpdate(filter: String?) {
        viewModel.onUpdate(filter: filter ?? "")
    }

}

extension WalletTokenListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return viewItems.count
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return tableView.dequeueReusableCell(withIdentifier: String(describing: WalletTokenCell.self), for: indexPath)
        default: return tableView.dequeueReusableCell(withIdentifier: String(describing: EmptyCell.self), for: indexPath)
        }

    }

}

extension WalletTokenListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? WalletTokenCell {
            bind(cell: cell, index: indexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return WalletTokenCell.height
        default: return .margin32
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            viewModel.didSelect(item: viewItems[indexPath.row])
        }
    }

}
