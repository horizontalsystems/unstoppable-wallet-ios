import Combine
import ComponentKit
import DeepDiff
import HUD
import MarketKit
import RxCocoa
import RxSwift
import SectionsTableView
import SwiftUI
import ThemeKit
import UIKit

class WalletViewController: ThemeViewController {
    private let animationDuration: TimeInterval = 0.2

    private let viewModel: WalletViewModel
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()

    private let placeholderView = PlaceholderView(layoutType: .bottom)

    private let spinner = HUDActivityView.create(with: .medium24)

    private let failedView = PlaceholderView()
    private let invalidApiKeyView = PlaceholderView()

    private var viewItems = [BalanceViewItem]()
    private var headerViewItem: WalletModule.HeaderViewItem?

    private var warningViewItem: CancellableTitledCaution?

    private var sortBy: String?
    private var controlViewItem: WalletViewModel.ControlViewItem?
    private var isLoaded = false

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet_view_controller", qos: .userInitiated)

    init(viewModel: WalletViewModel) {
        self.viewModel = viewModel

        super.init()

        tabBarItem = UITabBarItem(title: "balance.tab_bar_item".localized, image: UIImage(named: "filled_wallet_24"), tag: 0)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.sectionHeaderTopPadding = 0

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

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
        tableView.registerCell(forClass: WalletHeaderCell.self)
        tableView.registerCell(forClass: BalanceCell.self)
        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)
        tableView.registerCell(forClass: PlaceholderCell.self)
        tableView.registerHeaderFooter(forClass: WalletHeaderView.self)
        tableView.registerHeaderFooter(forClass: SectionColorHeader.self)

        view.addSubview(placeholderView)
        placeholderView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        placeholderView.image = UIImage(named: "add_to_wallet_48")

        placeholderView.addPrimaryButton(
            style: .yellow,
            title: "onboarding.balance.create".localized,
            target: self,
            action: #selector(onTapCreate)
        )

        placeholderView.addPrimaryButton(
            style: .gray,
            title: "onboarding.balance.import".localized,
            target: self,
            action: #selector(onTapRestore)
        )

        placeholderView.addPrimaryButton(
            style: .transparent,
            title: "onboarding.balance.watch".localized,
            target: self,
            action: #selector(onTapWatch)
        )

        view.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        spinner.startAnimating()

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

        subscribe(disposeBag, viewModel.titleDriver) { [weak self] in self?.navigationItem.title = $0 }
        subscribe(disposeBag, viewModel.showWarningDriver) { [weak self] in self?.sync(warning: $0) }
        subscribe(disposeBag, viewModel.openReceiveSignal) { [weak self] in self?.openReceive() }
        subscribe(disposeBag, viewModel.openElementSignal) { [weak self] in self?.open(element: $0) }
        subscribe(disposeBag, viewModel.openBackupRequiredSignal) { [weak self] in self?.openBackupRequired(account: $0) }
        subscribe(disposeBag, viewModel.noConnectionErrorSignal) { HudHelper.instance.show(banner: .noInternet) }
        subscribe(disposeBag, viewModel.openSyncErrorSignal) { [weak self] in self?.openSyncError(wallet: $0, error: $1) }
        subscribe(disposeBag, viewModel.showAccountsLostSignal) { [weak self] in self?.showAccountsLost() }
        subscribe(disposeBag, viewModel.playHapticSignal) { [weak self] in self?.playHaptic() }
        subscribe(disposeBag, viewModel.scrollToTopSignal) { [weak self] in self?.scrollToTop() }
        subscribe(disposeBag, viewModel.disableQrScannerSignal) { [weak self] in self?.qrScanning(disable: $0) }

        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(state: $0) }
            .store(in: &cancellables)

        viewModel.$headerViewItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(headerViewItem: $0) }
            .store(in: &cancellables)

        viewModel.$sortBy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(sortBy: $0) }
            .store(in: &cancellables)

        viewModel.$controlViewItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(controlViewItem: $0) }
            .store(in: &cancellables)

        viewModel.$nftVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(nftVisible: $0) }
            .store(in: &cancellables)

        viewModel.$qrScanVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(qrScanVisible: $0) }
            .store(in: &cancellables)

        sync(state: viewModel.state)
        sync(headerViewItem: viewModel.headerViewItem)
        sync(qrScanVisible: viewModel.qrScanVisible)

        isLoaded = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl

        viewModel.onAppear()
        showBackupPromptIfRequired()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.onDisappear()
    }

    @objc func onTapCreate() {
        let viewController = CreateAccountModule.viewController(sourceViewController: self, listener: self)
        present(viewController, animated: true)

        stat(page: .balance, event: .open(page: .newWallet))
    }

    @objc func onTapRestore() {
        let viewController = RestoreTypeModule.viewController(type: .wallet, sourceViewController: self)
        present(viewController, animated: true)

        stat(page: .balance, event: .open(page: .importWallet))
    }

    @objc func onTapWatch() {
        let viewController = WatchModule.viewController()
        present(viewController, animated: true)

        stat(page: .balance, event: .open(page: .watchWallet))
    }

    @objc func onRefresh() {
        viewModel.onTriggerRefresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }

        stat(page: .balance, event: .refresh)
    }

    @objc private func onTapSwitchWallet() {
        let viewController = ManageAccountsModule.viewController(mode: .switcher, createAccountListener: self)
        present(ThemeNavigationController(rootViewController: viewController), animated: true)

        stat(page: .balance, event: .open(page: .manageWallets))
    }

    @objc private func onTapNft() {
        guard let module = NftModule.viewController() else {
            return
        }

        navigationController?.pushViewController(module, animated: true)
    }

    @objc private func onTapQrScan() {
        let viewController = ScanQrViewController(reportAfterDismiss: true, pasteEnabled: true)
        viewController.didFetch = { [weak self] in self?.viewModel.process(scanned: $0) }
        present(viewController, animated: true)

        stat(page: .balance, event: .open(page: .scanQrCode))
    }

    @objc private func onTapRetry() {
        // todo
    }

    private func sync(nftVisible _: Bool) {
//        navigationItem.rightBarButtonItem = nftVisible ? UIBarButtonItem(image: UIImage(named: "nft_24"), style: .plain, target: self, action: #selector(onTapNft)) : nil
    }

    private func sync(qrScanVisible: Bool) {
        navigationItem.rightBarButtonItem = qrScanVisible ? UIBarButtonItem(image: UIImage(named: "qr_scan_24"), style: .plain, target: self, action: #selector(onTapQrScan)) : nil
    }

    private func sync(state: WalletViewModel.State) {
        switch state {
        case .noAccount:
            placeholderView.isHidden = false
            navigationItem.leftBarButtonItem = nil
        default:
            placeholderView.isHidden = true
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "switch_wallet_24"), style: .plain, target: self, action: #selector(onTapSwitchWallet))
            navigationItem.leftBarButtonItem?.tintColor = .themeJacob
        }

        switch state {
        case .loading: spinner.isHidden = false
        default: spinner.isHidden = true
        }

        switch state {
        case let .list(viewItems):
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
        case .syncFailed: failedView.isHidden = false
        default: failedView.isHidden = true
        }

        switch state {
        case .invalidApiKey: invalidApiKeyView.isHidden = false
        default: invalidApiKeyView.isHidden = true
        }
    }

    private func sync(headerViewItem: WalletModule.HeaderViewItem?) {
        let heightChanged = self.headerViewItem?.buttons.isEmpty != headerViewItem?.buttons.isEmpty

        self.headerViewItem = headerViewItem

        if isLoaded, let headerCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WalletHeaderCell {
            bind(headerCell: headerCell)

            if heightChanged {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }

    private func sync(sortBy: String?) {
        self.sortBy = sortBy

        if isLoaded, let headerView = tableView.headerView(forSection: 1) as? WalletHeaderView {
            headerView.set(sortByTitle: sortBy)
        }
    }

    private func sync(controlViewItem: WalletViewModel.ControlViewItem?) {
        self.controlViewItem = controlViewItem

        if isLoaded, let controlViewItem, let headerView = tableView.headerView(forSection: 1) as? WalletHeaderView {
            headerView.set(controlViewItem: controlViewItem)
        }
    }

    private func sync(warning: CancellableTitledCaution?) {
        let warningWasVisible = warningVisible
        warningViewItem = warning
        if isLoaded {
            if warningWasVisible, !warningVisible {
                tableView.beginUpdates()
                tableView.deleteRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
                tableView.endUpdates()
            } else {
                tableView.reloadData()
            }
        }
    }

    private func onOpenWarning() {
        guard let url = viewModel.warningUrl else {
            return
        }
        let module = MarkdownModule.viewController(url: url)
        DispatchQueue.main.async {
            let controller = ThemeNavigationController(rootViewController: module)
            if let delegate = module as? UIAdaptivePresentationControllerDelegate {
                controller.presentationController?.delegate = delegate
            }
            return self.present(controller, animated: true)
        }
    }

    private func onCloseWarning() {
        viewModel.onCloseWarning()
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
            case let .move(move):
                updateIndexes.insert(move.fromIndex)
                updateIndexes.insert(move.toIndex)
            case let .replace(replace):
                updateIndexes.insert(replace.index)
            default: ()
            }
        }

        viewItems = newViewItems

        UIView.animate(withDuration: animationDuration) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }

        for updateIndex in updateIndexes {
            if let cell = tableView.cellForRow(at: IndexPath(row: updateIndex, section: 1)) as? BalanceCell {
                bind(cell: cell, viewItem: viewItems[updateIndex])
            }
        }
    }

    private func bind(cell: BalanceCell, viewItem: BalanceViewItem) {
        cell.bind(
            viewItem: viewItem,
            onTapError: { [weak self] in
                self?.viewModel.onTapFailedIcon(element: viewItem.element)
            }
        )
    }

    private func bind(headerCell: WalletHeaderCell) {
        if let headerViewItem {
            headerCell.bind(viewItem: headerViewItem)
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

    private func openReceive() {
        if let viewController = ReceiveModule.viewController() {
            present(viewController, animated: true)
            stat(page: .balance, event: .open(page: .receiveTokenList))
        }
    }

    private func open(element: WalletModule.Element) {
        if let viewController = WalletTokenModule.viewController(element: element) {
            navigationController?.pushViewController(viewController, animated: true)

            stat(page: .balance, event: .openTokenPage(element: element))
        }
    }

    private func openDeposit(cexAsset: CexAsset) {
        guard let viewController = CexDepositModule.viewController(cexAsset: cexAsset) else {
            return
        }
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    private func openBackupRequired(account: Account) {
        let viewController = BottomSheetModule.backupRequiredPrompt(
            description: "receive_alert.any_coins.not_backed_up_description".localized(account.name),
            account: account,
            sourceViewController: self
        )

        present(viewController, animated: true)

        stat(page: .balance, event: .open(page: .backupRequired))
    }

    private func openSyncError(wallet: Wallet, error: Error) {
        let viewController = BalanceErrorModule.viewController(wallet: wallet, error: error, sourceViewController: navigationController)
        present(viewController, animated: true)
    }

    private func openManageWallets() {
        if let module = ManageWalletsModule.viewController() {
            present(module, animated: true)

            stat(page: .balance, event: .open(page: .coinManager))
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

    private func qrScanning(disable: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = !disable
    }

    private func handleRemove(indexPath: IndexPath) {
        let index = indexPath.row

        guard index < viewItems.count else {
            return
        }

        let element = viewItems[index].element

        viewItems.remove(at: index)

        tableView.beginUpdates()
        if viewItems.isEmpty {
            tableView.reloadRows(at: [indexPath], with: .fade)
        } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        tableView.endUpdates()

        viewModel.onDisable(element: element)

        if let token = element.wallet?.token {
            stat(page: .balance, event: .disableToken(token: token))
        }
    }

    private func bindHeaderActions(cell: WalletHeaderCell) {
        cell.onTapAmount = { [weak self] in self?.viewModel.onTapTotalAmount() }
        cell.onTapConvertedAmount = { [weak self] in self?.viewModel.onTapConvertedTotalAmount() }
        // Cex actions
        cell.actions[.deposit] = { [weak self] in
            if let viewController = CexCoinSelectModule.viewController(mode: .deposit) {
                self?.present(viewController, animated: true)
            }
        }
        cell.actions[.withdraw] = { [weak self] in
            if let viewController = CexCoinSelectModule.viewController(mode: .withdraw) {
                self?.present(viewController, animated: true)
            }
        }
        // Decentralized actions
        cell.actions[.send] = { [weak self] in
            guard let viewController = WalletModule.sendTokenListViewController() else {
                return
            }
            self?.present(viewController, animated: true)

            stat(page: .balance, event: .open(page: .sendTokenList))
        }

        cell.actions[.swap] = { [weak self] in
            let viewController = MultiSwapView().toViewController()
            self?.present(viewController, animated: true)

            stat(page: .balance, event: .open(page: .swap))
        }

        cell.actions[.receive] = { [weak self] in
            self?.viewModel.onTapReceive()
        }
    }

    private func showBackupPromptIfRequired() {
        guard let account = viewModel.lastCreatedAccount else {
            return
        }

        let viewController = BottomSheetModule.backupPromptAfterCreate(account: account, sourceViewController: self)
        present(viewController, animated: true)
    }

    private var warningVisible: Bool {
        warningViewItem != nil
    }
}

extension WalletViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        2
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 + (warningVisible ? 1 : 0)
        default: return viewItems.isEmpty ? 1 : viewItems.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WalletHeaderCell.self), for: indexPath)

                if let headerCell = cell as? WalletHeaderCell {
                    bindHeaderActions(cell: headerCell)
                }

                return cell
            } else {
                return tableView.dequeueReusableCell(withIdentifier: String(describing: TitledHighlightedDescriptionCell.self), for: indexPath)
            }
        default:
            if viewItems.isEmpty {
                return tableView.dequeueReusableCell(withIdentifier: String(describing: PlaceholderCell.self), for: indexPath)
            }

            return tableView.dequeueReusableCell(withIdentifier: String(describing: BalanceCell.self), for: indexPath)
        }
    }
}

extension WalletViewController: UITableViewDelegate {
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if let cell = cell as? WalletHeaderCell {
                bind(headerCell: cell)
            }

            if let cell = cell as? TitledHighlightedDescriptionCell, let warningViewItem {
                cell.set(backgroundStyle: .transparent, isFirst: true)
                cell.topOffset = .margin12
                cell.bind(caution: warningViewItem)
                cell.onBackgroundButton = { [weak self] in self?.onOpenWarning() }
                cell.onCloseButton = warningViewItem.cancellable ? { [weak self] in self?.onCloseWarning() } : nil
            }
        default:
            if let cell = cell as? BalanceCell {
                bind(cell: cell, viewItem: viewItems[indexPath.row])
            }

            if let cell = cell as? PlaceholderCell {
                cell.set(backgroundStyle: .transparent, isFirst: true)
                cell.icon = UIImage(named: "add_to_wallet_2_48")
                cell.text = "balance.empty.description".localized
            }
        }
    }

    func tableView(_: UITableView, willDisplayHeaderView view: UIView, forSection _: Int) {
        if let headerView = view as? WalletHeaderView {
            headerView.set(sortByTitle: sortBy)

            if let controlViewItem {
                headerView.set(controlViewItem: controlViewItem)
            }

            headerView.onTapSortBy = { [weak self] in self?.openSortType() }
            headerView.onTapSettings = { [weak self] in self?.openManageWallets() }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let headerHeight = {
            WalletHeaderCell.height(viewItem: self.headerViewItem)
        }

        let warningHeight = {
            TitledHighlightedDescriptionCell.height(containerWidth: tableView.width, text: self.warningViewItem?.text ?? "") + .margin32
        }

        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                return headerHeight()
            } else {
                return warningHeight()
            }
        default:
            if viewItems.isEmpty {
                var contentHeight: CGFloat = headerHeight() + WalletHeaderView.height

                if warningVisible {
                    contentHeight += warningHeight()
                }

                return max(200, tableView.height - tableView.safeAreaInsets.height - contentHeight)
            }

            return BalanceCell.height()
        }
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0: return 0
        default: return WalletHeaderView.height
        }
    }

    func tableView(_: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0: return 0
        default: return .margin8
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0: return nil
        default: return tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: WalletHeaderView.self))
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection _: Int) -> UIView? {
        tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: SectionColorHeader.self))
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            () // do nothing
        default:
            if viewItems.isEmpty {
                return
            }

            viewModel.onTap(element: viewItems[indexPath.item].element)
        }
    }

    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch indexPath.section {
        case 0:
            return nil
        default:
            if viewItems.isEmpty {
                return nil
            }

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
}

extension WalletViewController: ICreateAccountListener {
    func handleCreateAccount() {
        dismiss(animated: true) { [weak self] in
            self?.showBackupPromptIfRequired()
        }
    }
}
