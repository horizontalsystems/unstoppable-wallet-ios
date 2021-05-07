import UIKit
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import DeepDiff
import HUD
import CoinKit
import ComponentKit

class WalletViewController: ThemeViewController {
    private let animationDuration: TimeInterval = 0.2
    private let horizontalInset: CGFloat = .margin16
    private let lineSpacing: CGFloat = .margin8

    private let viewModel: WalletViewModel
    private let disposeBag = DisposeBag()

    private let layout = UICollectionViewFlowLayout()
    private let collectionView: UICollectionView
    private let refreshControl = UIRefreshControl()

    private let emptyView = UIView()

    private var viewItems = [BalanceViewItem]()
    private var headerViewItem: WalletViewModel.HeaderViewItem?
    private var isLoaded = false

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet_view_controller", qos: .userInitiated)

    init(viewModel: WalletViewModel) {
        self.viewModel = viewModel
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init()

        tabBarItem = UITabBarItem(title: "balance.tab_bar_item".localized, image: UIImage(named: "filled_wallet_24"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "switch_wallet_24"), style: .plain, target: self, action: #selector(onTapSwitchWallet))
        navigationItem.leftBarButtonItem?.tintColor = .themeJacob

        refreshControl.tintColor = .themeLeah
        refreshControl.alpha = 0.6
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        layout.sectionHeadersPinToVisibleBounds = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .clear

        collectionView.register(BalanceCell.self, forCellWithReuseIdentifier: String(describing: BalanceCell.self))
        collectionView.register(WalletHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: WalletHeaderView.self))

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

        subscribe(disposeBag, viewModel.titleDriver) { [weak self] in self?.navigationItem.title = $0 }
        subscribe(disposeBag, viewModel.displayModeDriver) { [weak self] in self?.sync(displayMode: $0) }
        subscribe(disposeBag, viewModel.headerViewItemDriver) { [weak self] in self?.sync(headerViewItem: $0) }
        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.openSortTypeSignal) { [weak self] in self?.openSortType() }
        subscribe(disposeBag, viewModel.openReceiveSignal) { [weak self] in self?.openReceive(wallet: $0) }
        subscribe(disposeBag, viewModel.openBackupRequiredSignal) { [weak self] in self?.openBackupRequired(wallet: $0) }
        subscribe(disposeBag, viewModel.openCoinPageSignal) { [weak self] in self?.openCoinPage(coin: $0) }
        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.openSyncErrorSignal) { [weak self] in self?.openSyncError(wallet: $0, error: $1) }
        subscribe(disposeBag, viewModel.showAccountsLostSignal) { [weak self] in self?.showAccountsLost() }
        subscribe(disposeBag, viewModel.playHapticSignal) { [weak self] in self?.playHaptic() }

        isLoaded = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        collectionView.refreshControl = refreshControl

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

    @objc private func onTapAddCoin() {
        openManageWallets()
    }

    private func sync(displayMode: WalletViewModel.DisplayMode) {
        collectionView.isHidden = displayMode != .list
        emptyView.isHidden = displayMode != .empty
    }

    private func sync(headerViewItem: WalletViewModel.HeaderViewItem?) {
        self.headerViewItem = headerViewItem

        if isLoaded, let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? WalletHeaderView {
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

        if changes.contains(where: {
            if case .insert = $0 { return true }
            if case .delete = $0 { return true }
            return false
        }) {
            DispatchQueue.main.sync {
                viewItems = newViewItems
                collectionView.reloadData()
            }
            return
        }

        var heightChange = false

        for (index, oldViewItem) in viewItems.enumerated() {
            let newViewItem = newViewItems[index]

            let oldHeight = BalanceCell.height(viewItem: oldViewItem)
            let newHeight = BalanceCell.height(viewItem: newViewItem)

            if oldHeight != newHeight {
                heightChange = true
                break
            }
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

            updateIndexes.forEach {
                if let cell = collectionView.cellForItem(at: IndexPath(row: $0, section: 0)) as? BalanceCell {
                    bind(cell: cell, viewItem: viewItems[$0], animated: heightChange)
                }
            }

            if heightChange {
                UIView.animate(withDuration: animationDuration) {
                    self.collectionView.performBatchUpdates(nil)
                }
            }
        }
    }

    private func bind(cell: BalanceCell, viewItem: BalanceViewItem, animated: Bool = false) {
        cell.bind(
                viewItem: viewItem,
                animated: animated,
                duration: animationDuration,
                onReceive: { [weak self] in
                    self?.viewModel.onTapReceive(wallet: viewItem.wallet)
                },
                onPay: { [weak self] in
                    self?.openSend(wallet: viewItem.wallet)
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
            headerView.bind(viewItem: viewItem)

            headerView.onTapAmount = { [weak self] in self?.viewModel.onTapTotalAmount() }
            headerView.onTapSortBy = { [weak self] in self?.viewModel.onTapSortBy() }
            headerView.onTapAddCoin = { [weak self] in self?.openManageWallets() }
        }
    }

    private func openSortType() {
        present(SortTypeRouter.module(), animated: true)
    }

    private func openReceive(wallet: Wallet) {
        if let module = DepositRouter.module(wallet: wallet) {
            present(module, animated: true)
        }
    }

    private func openSend(wallet: Wallet) {
        if let module = SendRouter.module(wallet: wallet) {
            present(module, animated: true)
        }
    }

    private func openSwap(wallet: Wallet) {
        if let module = SwapModule.viewController(coinIn: wallet.coin) {
            present(module, animated: true)
        }
    }

    private func openCoinPage(coin: Coin) {
        let viewController = CoinPageModule.viewController(launchMode: .coin(coin: coin))
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openBackupRequired(wallet: Wallet) {
        let text = "receive_alert.not_backed_up_description".localized(wallet.account.name, wallet.coin.title)
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

}

extension WalletViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: BalanceCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: WalletHeaderView.self), for: indexPath)
    }

}

extension WalletViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            bind(cell: cell, viewItem: viewItems[indexPath.item])
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if let headerView = view as? WalletHeaderView {
            bind(headerView: headerView)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.onTap(wallet: viewItems[indexPath.item].wallet)
    }

}

extension WalletViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.width - horizontalInset * 2, height: BalanceCell.height(viewItem: viewItems[indexPath.item]))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        lineSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: lineSpacing, left: horizontalInset, bottom: lineSpacing, right: horizontalInset)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: collectionView.width, height: WalletHeaderView.height)
    }

}
