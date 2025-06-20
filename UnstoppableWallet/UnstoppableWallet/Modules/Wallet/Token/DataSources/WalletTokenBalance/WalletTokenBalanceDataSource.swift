import Combine
import Foundation
import MarketKit
import SectionsTableView
import UIKit

class WalletTokenBalanceDataSource: NSObject {
    private let viewModel: WalletTokenBalanceViewModel
    private var cancellables: [AnyCancellable] = []

    private var headerViewItem: WalletTokenBalanceViewModel.ViewItem?
    private var buttons: [WalletModule.Button: ButtonState] = [:]
    private var tableView: UITableView?

    weak var parentViewController: UIViewController?
    weak var delegate: ISectionDataSourceDelegate?

    init(viewModel: WalletTokenBalanceViewModel) {
        self.viewModel = viewModel

        super.init()

        viewModel.playHapticPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.playHaptic()
            }
            .store(in: &cancellables)

        viewModel.noConnectionErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { HudHelper.instance.show(banner: .noInternet) }
            .store(in: &cancellables)

        viewModel.openSyncErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.openSyncError(wallet: $0, error: $1)
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
        let oldStatesCount = self.headerViewItem?.customStates.count ?? 0
        self.headerViewItem = headerViewItem

        guard oldStatesCount == headerViewItem?.customStates.count ?? 0 else {
            tableView?.reloadData()
            return
        }

        if let tableView {
            let firstIndexPath = IndexPath(row: 0, section: 0)
            let originalIndexPath = delegate?
                .originalIndexPath(tableView: tableView, dataSource: self, indexPath: firstIndexPath) ?? firstIndexPath

            if let headerCell = tableView.cellForRow(at: originalIndexPath) as? WalletTokenBalanceCell {
                bind(cell: headerCell)
            }

            headerViewItem?.customStates.enumerated().forEach { index, _ in
                let indexPath = IndexPath(row: index, section: 1)
                let originalIndexPath = delegate?
                    .originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath

                if let cell = tableView.cellForRow(at: originalIndexPath) as? WalletTokenBalanceCustomAmountCell {
                    bind(cell: cell, row: index)
                }
            }
        }
    }

    private func sync(buttons: [WalletModule.Button: ButtonState]) {
        self.buttons = buttons

        guard let tableView else {
            return
        }
        let indexPath = IndexPath(row: 1, section: 0)
        let originalIndexPath = delegate?
            .originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath

        if let cell = tableView.cellForRow(at: originalIndexPath) as? BalanceButtonsCell {
            bind(cell: cell)
        }
    }

    private func bind(cell: WalletTokenBalanceCell) {
        if let headerViewItem {
            cell.bind(viewItem: headerViewItem) { [weak self] in
                self?.viewModel.onTapFailedIcon()
            }

            if let tableView {
                UIView.animate(withDuration: 0.3) {
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
            }
        }
    }

    private func bind(cell: BalanceButtonsCell) {
        cell.bind(buttons: buttons)
    }

    private func bind(cell: WalletTokenBalanceCustomAmountCell, row: Int) {
        guard let count = headerViewItem?.customStates.count,
              let item = headerViewItem?.customStates.at(index: row)
        else {
            return
        }
        cell.set(backgroundStyle: .externalBorderOnly, cornerRadius: .margin12, isFirst: row == 0, isLast: row == count - 1)
        cell.bind(title: item.title, amount: item.amountValue?.text, dimmed: item.amountValue?.dimmed ?? false)
    }

    private func bindActions(cell: BalanceButtonsCell) {
        let wallet = viewModel.wallet

        cell.actions[.send] = { [weak self] in
            let module = SendAddressView(wallet: wallet).toNavigationViewController()

            self?.parentViewController?.present(module, animated: true)
            stat(page: .tokenPage, event: .openSend(token: wallet.token))
        }
        cell.actions[.swap] = { [weak self] in
            let viewController = MultiSwapView(token: wallet.token).toViewController()
            self?.parentViewController?.present(viewController, animated: true)
            stat(page: .tokenPage, event: .open(page: .swap))
        }
        cell.actions[.receive] = { [weak self] in
            self?.viewModel.onTapReceive()
        }

        cell.actions[.chart] = { [weak self] in
            self?.viewModel.onTapChart()
        }
    }

    private func playHaptic() {
        HapticGenerator.instance.notification(.feedback(.soft))
    }

    private func openSyncError(wallet: Wallet, error: Error) {
        let viewController = BalanceErrorModule.viewController(wallet: wallet, error: error, sourceViewController: parentViewController)
        parentViewController?.present(viewController, animated: true)
    }

    private func openReceive(wallet: Wallet) {
        let view = ReceiveAddressView(wallet: wallet)
        parentViewController?.present(view.toNavigationViewController(), animated: true)
        stat(page: .tokenPage, event: .openReceive(token: wallet.token))
    }

    private func openCoinPage(coin: Coin) {
        let viewController = CoinPageView(coin: coin).toViewController()
        parentViewController?.present(viewController, animated: true)

        stat(page: .tokenPage, event: .openCoin(coinUid: coin.uid))
    }

    private func openBackupRequired(wallet: Wallet) {
        let viewController = BottomSheetModule.backupRequiredPrompt(
            description: "receive_alert.not_backed_up_description".localized(wallet.account.name, wallet.coin.name),
            account: wallet.account,
            sourceViewController: parentViewController
        )

        parentViewController?.present(viewController, animated: true)
        stat(page: .tokenPage, event: .open(page: .backupRequired))
    }
}

extension WalletTokenBalanceDataSource: ISectionDataSource {
    func prepare(tableView: UITableView) {
        tableView.registerCell(forClass: WalletTokenBalanceCell.self)
        tableView.registerCell(forClass: BalanceButtonsCell.self)
        tableView.registerCell(forClass: WalletTokenBalanceCustomAmountCell.self)
        tableView.registerHeaderFooter(forClass: SectionColorHeader.self)
        self.tableView = tableView
    }
}

extension WalletTokenBalanceDataSource: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        1 + ((headerViewItem?.customStates.isEmpty ?? true) ? 0 : 1)
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return headerViewItem?.customStates.count ?? 0
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WalletTokenBalanceCell.self), for: originalIndexPath)
                if let cell = cell as? WalletTokenBalanceCell {
                    cell.onTapAmount = { [weak self] in
                        self?.viewModel.onTapAmount()
                    }
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
        case 1:
            return tableView.dequeueReusableCell(withIdentifier: String(describing: WalletTokenBalanceCustomAmountCell.self), for: originalIndexPath)
        default: ()
        }

        return UITableViewCell()
    }
}

extension WalletTokenBalanceDataSource: UITableViewDelegate {
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? WalletTokenBalanceCell {
            bind(cell: cell)
        }
        if let cell = cell as? BalanceButtonsCell {
            bind(cell: cell)
        }
        if let cell = cell as? WalletTokenBalanceCustomAmountCell {
            bind(cell: cell, row: indexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return WalletTokenBalanceCell.height(containerWidth: tableView.width, viewItem: headerViewItem)
            default: return BalanceButtonsCell.height
            }
        case 1: return .heightSingleLineCell
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0, 1:
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: SectionColorHeader.self)) as? SectionColorHeader
            view?.backgroundView?.backgroundColor = .clear
            return view
        default: return nil
        }
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0: return .margin12
        case 1: return .margin8
        default: return .zero
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath
            tableView.deselectRow(at: originalIndexPath, animated: true)

            if let viewItem = headerViewItem?.customStates.at(index: indexPath.row) {
                switch viewItem.action {
                case .none:
                    let viewController = BottomSheetModule.description(title: viewItem.infoTitle, text: viewItem.infoDescription)
                    parentViewController?.present(viewController, animated: true)
                case let .unshield(amount):
                    let shieldButton = BottomSheetModule.Button(style: .yellow, title: "balance.token.shield".localized, actionType: .afterClose) { [weak self] in
                        let module = ShieldSendView(amount: amount, address: nil).toNavigationViewController()
                        self?.parentViewController?.present(module, animated: true)
                    }
                    let viewController = BottomSheetModule.description(title: viewItem.infoTitle, text: viewItem.infoDescription, buttons: [shieldButton])
                    parentViewController?.present(viewController, animated: true)
                }
            }
        default: ()
        }
    }
}
