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

class WalletSendViewController: ThemeSearchViewController {
    private let animationDuration: TimeInterval = 0.2

    private let viewModel: WalletSendViewModel
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()

    private let spinner = HUDActivityView.create(with: .medium24)

    private let emptyView = PlaceholderView()
    private let failedView = PlaceholderView()
    private let invalidApiKeyView = PlaceholderView()

    private var viewItems = [SendViewItem]()
    private var isLoaded = false

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet_send_view_controller", qos: .userInitiated)

    init(viewModel: WalletSendViewModel) {
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

        title = "Send".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapClose))
        navigationItem.searchController?.searchBar.placeholder = "add_token.coin_name".localized

        refreshControl.tintColor = .themeLeah
        refreshControl.alpha = 0.6
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false

        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerCell(forClass: SendCell.self)

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
        emptyView.text = "You have no assets to send.".localized

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
        subscribe(disposeBag, viewModel.openSendSignal) { [weak self] in self?.openSend(wallet: $0) }
        subscribe(disposeBag, viewModel.openSyncErrorSignal) { [weak self] in self?.openSyncError(wallet: $0, error: $1) }
        subscribe(disposeBag, viewModel.showAccountsLostSignal) { [weak self] in self?.showAccountsLost() }

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl

        viewModel.onAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.onDisappear()
    }

    @objc func onTapClose() {
        dismiss(animated: true)
    }

    @objc func onTapCreate() {
        let viewController = CreateAccountModule.viewController(sourceViewController: self)
        present(viewController, animated: true)
    }

    @objc func onTapRestore() {
        let viewController = RestoreTypeModule.viewController(sourceViewController: self)
        present(viewController, animated: true)
    }

    @objc func onTapWatch() {
        let viewController = WatchModule.viewController()
        present(viewController, animated: true)
    }

    @objc func onRefresh() {
        viewModel.onTriggerRefresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    @objc private func onTapRetry() {
        // todo
    }

    private func sync(state: WalletSendViewModel.State) {
        switch state {
        case .list(let viewItems): navigationItem.searchController?.searchBar.isHidden = viewItems.isEmpty
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

    private func handle(newViewItems: [SendViewItem]) {
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
            if let cell = tableView.cellForRow(at: IndexPath(row: $0, section: 0)) as? SendCell {
                bind(cell: cell, viewItem: viewItems[$0], animated: true)
            }
        }
    }

    private func bind(cell: SendCell, viewItem: SendViewItem, animated: Bool = false) {
        cell.bind(
                viewItem: viewItem,
                animated: animated,
                duration: animationDuration,
                onTapError: { [weak self] in
                    self?.viewModel.onTapFailedIcon(element: viewItem.element)
                }
        )
    }

    private func openSend(wallet: Wallet) {
        if let module = SendModule.controller(wallet: wallet) {
            present(module, animated: true)
        }
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

extension WalletSendViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: String(describing: SendCell.self), for: indexPath)
    }

}

extension WalletSendViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? SendCell {
            bind(cell: cell, viewItem: viewItems[indexPath.row])
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        SendCell.height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelect(item: viewItems[indexPath.item])
    }

}
