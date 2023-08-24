import Combine
import Foundation
import UIKit
import HUD
import MarketKit
import ThemeKit

class WalletTokenBalanceDataSource: NSObject {
    private let viewModel: WalletTokenBalanceViewModel
    private var cancellables: [AnyCancellable] = []

    private var headerViewItem: WalletTokenBalanceViewModel.ViewItem?
    private var buttons: [WalletModule.Button: ButtonState] = [:]
    private var tableView: UITableView?

    weak var parentViewController: UIViewController?
    weak var indexPathConverter: ISectionDataSourceIndexPathConverter?

    init(viewModel: WalletTokenBalanceViewModel) {
        self.viewModel = viewModel

        super.init()

        viewModel.playHapticPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.playHaptic()
                }
                .store(in: &cancellables)

        viewModel.openReceivePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.openReceive(wallet: $0)
                }
                .store(in: &cancellables)

        viewModel.openBackupRequiredPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.openBackupRequired(wallet: $0)
                }
                .store(in: &cancellables)

        viewModel.openCoinPagePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.openCoinPage(coin: $0)
                }
                .store(in: &cancellables)

        viewModel.$viewItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.sync(headerViewItem: $0)
                }
                .store(in: &cancellables)

        viewModel.$buttons
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.sync(buttons: $0)
                }
                .store(in: &cancellables)

        sync(headerViewItem: viewModel.viewItem)
        sync(buttons: viewModel.buttons)
    }

    private func sync(headerViewItem: WalletTokenBalanceViewModel.ViewItem?) {
        self.headerViewItem = headerViewItem

        if let headerCell = tableView?.cellForRow(at: IndexPath(row: 0, section: 0)) as? WalletTokenBalanceCell {
            bind(cell: headerCell)
        }
    }

    private func sync(buttons: [WalletModule.Button: ButtonState]) {
        self.buttons = buttons

        if let cell = tableView?.cellForRow(at: IndexPath(row: 1, section: 0)) as? BalanceButtonsCell {
            bind(cell: cell)
        }
    }

    private func bind(cell: WalletTokenBalanceCell) {
        if let headerViewItem {
            cell.bind(viewItem: headerViewItem) {
                print("tap error")
            }
        }
    }

    private func bind(cell: BalanceButtonsCell) {
        cell.bind(buttons: buttons)
    }

    private func bindActions(cell: BalanceButtonsCell) {
        switch viewModel.element {
        case .cexAsset(let cexAsset):
            cell.actions[.deposit] = { [weak self] in
                if let viewController = CexDepositModule.viewController(cexAsset: cexAsset) {
                    self?.parentViewController?.navigationController?.pushViewController(viewController, animated: true)
                }
            }
            cell.actions[.withdraw] = { [weak self] in
                if let viewController = CexWithdrawModule.viewController(cexAsset: cexAsset) {
                    self?.parentViewController?.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        case .wallet(let wallet):
            cell.actions[.send] = { [weak self] in
                if let viewController = SendModule.controller(wallet: wallet) {
                    self?.parentViewController?.present(viewController, animated: true)
                }
            }
            cell.actions[.swap] = { [weak self] in
                if let viewController = SwapModule.viewController(tokenFrom: wallet.token) {
                    let navigationController = ThemeNavigationController(rootViewController: viewController)
                    self?.parentViewController?.present(navigationController, animated: true)
                }
            }
            cell.actions[.receive] = { [weak self] in
                self?.viewModel.onTapReceive()
            }
            cell.actions[.chart] = { [weak self] in
                self?.viewModel.onTapChart()
            }
        }
    }

    private func playHaptic() {
        HapticGenerator.instance.notification(.feedback(.soft))
    }

    private func openReceive(wallet: Wallet) {
        guard let viewController = ReceiveAddressModule.viewController(wallet: wallet) else {
            return
        }
        let navigationController = ThemeNavigationController(rootViewController: viewController)
        parentViewController?.present(navigationController, animated: true)
    }

    private func openCoinPage(coin: Coin) {
        if let viewController = CoinPageModule.viewController(coinUid: coin.uid) {
            parentViewController?.present(viewController, animated: true)
        }
    }

    private func openBackupRequired(wallet: Wallet) {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "backup_required.title".localized,
                items: [
                    .highlightedDescription(text: "receive_alert.not_backed_up_description".localized(wallet.account.name, wallet.coin.name))
                ],
                buttons: [
                    .init(style: .yellow, title: "backup_prompt.backup_manual".localized, imageName: "edit_24", actionType: .afterClose) { [ weak self] in
                        guard let viewController = BackupModule.manualViewController(account: wallet.account) else {
                            return
                        }

                        self?.parentViewController?.present(viewController, animated: true)
                    },
                    .init(style: .gray, title: "backup_prompt.backup_cloud".localized, imageName: "icloud_24", actionType: .afterClose) { [ weak self] in
                        let viewController = BackupModule.cloudViewController(account: wallet.account)
                        self?.parentViewController?.present(viewController, animated: true)
                    },
                    .init(style: .transparent, title: "button.cancel".localized)
                ]
        )

        parentViewController?.present(viewController, animated: true)
    }

}

extension WalletTokenBalanceDataSource: ISectionDataSource {

    func prepare(tableView: UITableView) {
        tableView.registerCell(forClass: WalletTokenBalanceCell.self)
        tableView.registerCell(forClass: BalanceButtonsCell.self)
        self.tableView = tableView
    }

}

extension WalletTokenBalanceDataSource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let originalIndexPath = indexPathConverter?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WalletTokenBalanceCell.self), for: originalIndexPath)
                if let cell = cell as? WalletTokenBalanceCell {
                    cell.onTapAmount = { [weak self] in self?.viewModel.onTapAmount() }
                }
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: BalanceButtonsCell.self), for: originalIndexPath)
                if let cell = cell as? BalanceButtonsCell {
                    bindActions(cell: cell)
                }

                return cell
            default: ()
            }
        }

        fatalError("Wrong cell indexPath :\(indexPath)")
    }

}

extension WalletTokenBalanceDataSource: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? WalletTokenBalanceCell {
            bind(cell: cell)
        }
        if let cell = cell as? BalanceButtonsCell {
            bind(cell: cell)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0: return WalletTokenBalanceCell.height(viewItem: headerViewItem)
            case 1: return BalanceButtonsCell.height
            default: return 0
            }
        }

        return 0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return .margin12
        }
        return .zero
    }

}
