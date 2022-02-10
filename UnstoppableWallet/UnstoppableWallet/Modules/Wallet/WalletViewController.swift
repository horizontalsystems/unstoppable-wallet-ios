import UIKit
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import DeepDiff
import HUD
import MarketKit
import ComponentKit

class WalletViewController: ThemeViewController {
    private let animationDuration: TimeInterval = 0.2

    private let viewModel: WalletViewModel
    private let disposeBag = DisposeBag()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()

    private let emptyView = UIView()
    private let watchEmptyView = UIView()

    private var viewItems = [BalanceViewItem]()
    private var headerViewItem: WalletViewModel.HeaderViewItem?
    private var sortBy: String?
    private var isLoaded = false

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet_view_controller", qos: .userInitiated)

    init(viewModel: WalletViewModel) {
        self.viewModel = viewModel

        super.init()

        tabBarItem = UITabBarItem(title: "balance.tab_bar_item".localized, image: UIImage(named: "filled_wallet_24"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "switch_wallet_24"), style: .plain, target: self, action: #selector(onTapSwitchWallet))
        navigationItem.leftBarButtonItem?.tintColor = .themeJacob

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "nft_24"), style: .plain, target: self, action: #selector(onTapNft))

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
        tableView.registerCell(forClass: BalanceCell.self)
        tableView.registerHeaderFooter(forClass: WalletHeaderView.self)
        tableView.registerHeaderFooter(forClass: SectionColorHeader.self)

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        let cautionView = CircleCautionView()

        emptyView.addSubview(cautionView)
        cautionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.top.equalToSuperview()
        }

        cautionView.image = UIImage(named: "add_to_wallet_2_48")
        cautionView.text = "balance.empty.description".localized

        let addCoinButton = ThemeButton()

        emptyView.addSubview(addCoinButton)
        addCoinButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(cautionView.snp.bottom).offset(CGFloat.margin32)
            maker.bottom.equalToSuperview()
        }

        addCoinButton.apply(style: .secondaryDefault)
        addCoinButton.setTitle("balance.empty.add_coins".localized, for: .normal)
        addCoinButton.addTarget(self, action: #selector(onTapAddCoin), for: .touchUpInside)

        view.addSubview(watchEmptyView)
        watchEmptyView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        let watchCautionView = CircleCautionView()

        watchEmptyView.addSubview(watchCautionView)
        watchCautionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.top.bottom.equalToSuperview()
        }

        watchCautionView.image = UIImage(named: "empty_wallet_48")
        watchCautionView.text = "balance.watch_empty.description".localized

        subscribe(disposeBag, viewModel.titleDriver) { [weak self] in self?.navigationItem.title = $0 }
        subscribe(disposeBag, viewModel.displayModeDriver) { [weak self] in self?.sync(displayMode: $0) }
        subscribe(disposeBag, viewModel.headerViewItemDriver) { [weak self] in self?.sync(headerViewItem: $0) }
        subscribe(disposeBag, viewModel.sortByDriver) { [weak self] in self?.sync(sortBy: $0) }
        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.openReceiveSignal) { [weak self] in self?.openReceive(wallet: $0) }
        subscribe(disposeBag, viewModel.openBackupRequiredSignal) { [weak self] in self?.openBackupRequired(wallet: $0) }
        subscribe(disposeBag, viewModel.openCoinPageSignal) { [weak self] in self?.openCoinPage(coin: $0) }
        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.openSyncErrorSignal) { [weak self] in self?.openSyncError(wallet: $0, error: $1) }
        subscribe(disposeBag, viewModel.showAccountsLostSignal) { [weak self] in self?.showAccountsLost() }
        subscribe(disposeBag, viewModel.playHapticSignal) { [weak self] in self?.playHaptic() }
        subscribe(disposeBag, viewModel.scrollToTopSignal) { [weak self] in self?.scrollToTop() }

        isLoaded = true
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

    @objc func onRefresh() {
        viewModel.onTriggerRefresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    @objc private func onTapSwitchWallet() {
        let viewController = ManageAccountsModule.viewController(mode: .switcher)
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    @objc private func onTapNft() {
        navigationController?.pushViewController(NftCollectionsModule.viewController(), animated: true)
    }

    @objc private func onTapAddCoin() {
        openManageWallets()
    }

    private func sync(displayMode: WalletViewModel.DisplayMode) {
        tableView.isHidden = displayMode != .list
        emptyView.isHidden = displayMode != .empty
        watchEmptyView.isHidden = displayMode != .watchEmpty
    }

    private func sync(headerViewItem: WalletViewModel.HeaderViewItem?) {
        self.headerViewItem = headerViewItem

        if isLoaded, let headerView = tableView.headerView(forSection: 0) as? WalletHeaderView {
            bind(headerView: headerView)
        }
    }

    private func sync(sortBy: String?) {
        self.sortBy = sortBy

        if isLoaded, let headerView = tableView.headerView(forSection: 0) as? WalletHeaderView {
            bind(headerView: headerView)
        }
    }

    private func sync(viewItems: [BalanceViewItem]) {
        if isLoaded {
            queue.async { [weak self] in
                self?.handle(newViewItems: viewItems)
            }
        } else {
            self.viewItems = viewItems
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
            DispatchQueue.main.sync {
                viewItems = newViewItems
                tableView.reloadData()
            }
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

        DispatchQueue.main.sync {
            viewItems = newViewItems

            UIView.animate(withDuration: animationDuration) {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }

            updateIndexes.forEach {
                if let cell = tableView.cellForRow(at: IndexPath(row: $0, section: 0)) as? BalanceCell {
                    bind(cell: cell, viewItem: viewItems[$0], animated: true)
                }
            }
        }
    }

    private func bind(cell: BalanceCell, viewItem: BalanceViewItem, animated: Bool = false) {
        cell.bind(
                viewItem: viewItem,
                animated: animated,
                duration: animationDuration,
                onSend: { [weak self] in
                    self?.openSend(wallet: viewItem.wallet)
                },
                onReceive: { [weak self] in
                    self?.viewModel.onTapReceive(wallet: viewItem.wallet)
                },
                onSwap: { [weak self] in
                    self?.openSwap(wallet: viewItem.wallet)
                },
                onChart: { [weak self] in
                    self?.viewModel.onTapChart(wallet: viewItem.wallet)
                },
                onTapError: { [weak self] in
                    self?.viewModel.onTapFailedIcon(wallet: viewItem.wallet)
                }
        )
    }

    private func bind(headerView: WalletHeaderView) {
        if let viewItem = headerViewItem {
            headerView.bind(viewItem: viewItem, sortBy: sortBy)

            headerView.onTapAmount = { [weak self] in self?.viewModel.onTapTotalAmount() }
            headerView.onTapSortBy = { [weak self] in self?.openSortType() }
            headerView.onTapAddCoin = { [weak self] in self?.openManageWallets() }
        }
    }

    private func openSortType() {
        let alertController = AlertRouter.module(
                title: "balance.sort.header".localized,
                viewItems: viewModel.sortTypeViewItems
        ) { [weak self] index in
            self?.viewModel.onSelectSortType(index: index)
        }

        present(alertController, animated: true)
    }

    private func openReceive(wallet: Wallet) {
        if let module = DepositModule.viewController(wallet: wallet) {
            present(module, animated: true)
        }
    }

    private func openSend(wallet: Wallet) {
        if let module = SendRouter.module(wallet: wallet) {
            present(module, animated: true)
        }
    }

    private func openSwap(wallet: Wallet) {
        if let module = SwapModule.viewController(platformCoinFrom: wallet.platformCoin) {
            present(module, animated: true)
        }
    }

    private func openCoinPage(coin: Coin) {
        if let viewController = CoinPageModule.viewController(coinUid: coin.uid) {
            present(viewController, animated: true)
        }
    }

    private func openBackupRequired(wallet: Wallet) {
        let text = "receive_alert.not_backed_up_description".localized(wallet.account.name, wallet.coin.name)
        let module = BackupRequiredViewController(account: wallet.account, text: text, sourceViewController: self).toBottomSheet
        present(module, animated: true)
    }

    private func openSyncError(wallet: Wallet, error: Error) {
        let viewController = BalanceErrorRouter.module(wallet: wallet, error: error, navigationController: navigationController)
        present(viewController, animated: true)
    }

    private func show(error: String) {
        HudHelper.instance.showError(title: error)
    }

    private func openManageWallets() {
        if let module = ManageWalletsModule.viewController() {
            present(module, animated: true)
        }
    }

    private func showAccountsLost() {
        let controller = UIAlertController(title: "lost_accounts.warning_title".localized, message: "lost_accounts.warning_message".localized, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "button.ok".localized, style: .default))
        controller.show()
    }

    private func playHaptic() {
        HapticGenerator.instance.notification(.feedback(.soft))
    }

    private func scrollToTop() {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }

    private func handleRemove(indexPath: IndexPath) {
        let index = indexPath.row

        guard index < viewItems.count else {
            return
        }

        let wallet = viewItems[index].wallet

        viewItems.remove(at: index)

        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .fade)
        tableView.endUpdates()

        viewModel.onDisable(wallet: wallet)
    }

}

extension WalletViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: String(describing: BalanceCell.self), for: indexPath)
    }

}

extension WalletViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            bind(cell: cell, viewItem: viewItems[indexPath.item])
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? WalletHeaderView {
            bind(headerView: headerView)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        BalanceCell.height(viewItem: viewItems[indexPath.row])
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        WalletHeaderView.height
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .margin8
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: WalletHeaderView.self))
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: SectionColorHeader.self))
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.onTap(wallet: viewItems[indexPath.item].wallet)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewModel.swipeActionsEnabled else {
            return nil
        }

        let action = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            self?.handleRemove(indexPath: indexPath)
            completion(true)
        }

        action.image = UIImage(named: "circle_minus_shifted_24")
        action.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)

        return UISwipeActionsConfiguration(actions: [action])
    }

}
