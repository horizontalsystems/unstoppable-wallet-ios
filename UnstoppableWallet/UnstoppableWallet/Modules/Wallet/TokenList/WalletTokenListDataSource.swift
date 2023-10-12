import Combine
import UIKit
import DeepDiff
import RxSwift
import RxCocoa
import ComponentKit
import HUD
import MarketKit
import SectionsTableView
import ThemeKit

class WalletTokenListDataSource: NSObject {
    private let animationDuration: TimeInterval = 0.2

    private let viewModel: WalletTokenListViewModel
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    private var viewItems = [BalanceViewItem]()
    private var customCell: CustomCell = .none
    private var isLoaded = false

    var onSelectWallet: ((Wallet) -> ())?

    weak var viewController: UIViewController?
    private weak var tableView: UITableView?
    weak var delegate: ISectionDataSourceDelegate?

    init(viewModel: WalletTokenListViewModel) {
        self.viewModel = viewModel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapRetry() {
        // todo
    }

    private func sync(state: WalletTokenListViewModel.State) {
        switch state {
        case .loading: customCell = .spinner
        case .list(let viewItems): customCell = viewItems.isEmpty ? .noResults : .none
        case .empty, .noAccount: customCell = .empty
        case .syncFailed: customCell = .failed
        case .invalidApiKey: customCell = .invalidApiKey
        }

        switch state {
        case .list(let viewItems):
            viewController?.navigationItem.searchController?.searchBar.isHidden = false
            if isLoaded {
                handle(newViewItems: viewItems)
            } else {
                self.viewItems = viewItems
            }
        default:
            viewController?.navigationItem.searchController?.searchBar.isHidden = true
        }
    }

    private func handle(newViewItems: [BalanceViewItem]) {
        let changes = diff(old: viewItems, new: newViewItems)

        guard !changes.isEmpty else {
            return
        }

        if changes.contains(where: {
            if case .insert = $0 {
                return true
            }
            if case .delete = $0 {
                return true
            }
            return false
        }) {
            viewItems = newViewItems
            tableView?.reloadData()
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
            self.tableView?.beginUpdates()
            self.tableView?.endUpdates()
        }

        if let tableView {
            updateIndexes.forEach {
                let indexPath = IndexPath(row: $0, section: 0)
                let originalIndexPath = delegate?
                    .originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath

                if let cell = tableView.cellForRow(at: originalIndexPath) as? WalletTokenCell {
                    let hideTopSeparator = originalIndexPath.row == 0 && originalIndexPath.section != 0
                    bind(cell: cell, index: $0, hideTopSeparator: hideTopSeparator, animated: true)
                }
            }
        }
    }

    private func bind(cell: WalletTokenCell, index: Int, hideTopSeparator: Bool, animated: Bool = false) {
        let viewItem = viewItems[index]

        cell.set(backgroundStyle: .transparent, isFirst: hideTopSeparator, isLast: index == viewItems.count - 1)

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
        let viewController = BalanceErrorModule.viewController(wallet: wallet, error: error, sourceViewController: viewController?.navigationController)
        self.viewController?.present(viewController, animated: true)
    }

    private func showAccountsLost() {
        let controller = UIAlertController(title: "lost_accounts.warning_title".localized, message: "lost_accounts.warning_message".localized, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "button.ok".localized, style: .default))
        controller.show()
    }

}

extension WalletTokenListDataSource: ISectionDataSource {

    func prepare(tableView: UITableView) {
        self.tableView = tableView

        tableView.registerCell(forClass: WalletTokenCell.self)
        tableView.registerCell(forClass: EmptyCell.self)
        tableView.registerCell(forClass: PlaceholderCell.self)
        tableView.registerCell(forClass: SpinnerCell.self)

        // setup filter for search results if viewController has search
        if let viewController = viewController as? ThemeSearchViewController {
            viewController.$filter
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.viewModel.onUpdate(filter: $0 ?? "") }
                    .store(in: &cancellables)
        }

        subscribe(disposeBag, viewModel.noConnectionErrorSignal) { HudHelper.instance.show(banner: .noInternet) }
        subscribe(disposeBag, viewModel.showSyncingSignal) { HudHelper.instance.show(banner: .attention(string: "wait_for_synchronization".localized)) }
        subscribe(disposeBag, viewModel.selectWalletSignal) { [weak self] in self?.onSelect(wallet: $0) }
        subscribe(disposeBag, viewModel.openSyncErrorSignal) { [weak self] in self?.openSyncError(wallet: $0, error: $1) }

        viewModel.$state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.sync(state: $0)
                }
                .store(in: &cancellables)

        sync(state: viewModel.state)

        isLoaded = true
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        (viewItems.isEmpty ? 0 : 1) + 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewItems.isEmpty {
            return 1
        } else {
            switch section {
            case 0: return viewItems.count
            default: return 1
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath

        if viewItems.isEmpty {
            switch customCell {
            case .none: return tableView.dequeueReusableCell(withIdentifier: String(describing: EmptyCell.self), for: indexPath)
            case .empty: return tableView.dequeueReusableCell(withIdentifier: String(describing: PlaceholderCell.self), for: originalIndexPath)
            case .noResults: return tableView.dequeueReusableCell(withIdentifier: String(describing: PlaceholderCell.self), for: originalIndexPath)
            case .spinner: return tableView.dequeueReusableCell(withIdentifier: String(describing: SpinnerCell.self), for: originalIndexPath)
            case .failed: return tableView.dequeueReusableCell(withIdentifier: String(describing: PlaceholderCell.self), for: originalIndexPath)
            case .invalidApiKey: return tableView.dequeueReusableCell(withIdentifier: String(describing: PlaceholderCell.self), for: originalIndexPath)
            }
        }

        switch indexPath.section {
        case 0: return tableView.dequeueReusableCell(withIdentifier: String(describing: WalletTokenCell.self), for: originalIndexPath)
        default: return tableView.dequeueReusableCell(withIdentifier: String(describing: EmptyCell.self), for: originalIndexPath)
        }

    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if viewItems.isEmpty {
            switch customCell {
            case .none: ()
            case .empty:
                if let cell = cell as? PlaceholderCell {
                    cell.set(backgroundStyle: .transparent, isFirst: true)
                    cell.icon = UIImage(named: "empty_wallet_48")
                    cell.text = viewModel.emptyText
                    cell.removeAllButtons()
                }
            case .noResults:
                if let cell = cell as? PlaceholderCell {
                    cell.set(backgroundStyle: .transparent, isFirst: true)
                    cell.icon = UIImage(named: "not_found_48")
                    cell.text = "market_discovery.not_found".localized
                    cell.removeAllButtons()
                }
            case .spinner: ()
            case .failed:
                if let cell = cell as? PlaceholderCell {
                    cell.set(backgroundStyle: .transparent, isFirst: true)
                    cell.icon = UIImage(named: "sync_error_48")
                    cell.text = "sync_error".localized
                    cell.removeAllButtons()
                    cell.addPrimaryButton(
                            style: .yellow,
                            title: "button.retry".localized,
                            target: self,
                            action: #selector(onTapRetry)
                    )
                }
            case .invalidApiKey:
                if let cell = cell as? PlaceholderCell {
                    cell.set(backgroundStyle: .transparent, isFirst: true)
                    cell.icon = UIImage(named: "not_available_48")
                    cell.text = "balance.invalid_api_key".localized
                    cell.removeAllButtons()
                }
            }
        }

        if let cell = cell as? WalletTokenCell {
            let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath
            let hideTopSeparator = originalIndexPath.row == 0 && originalIndexPath.section != 0
            bind(cell: cell, index: indexPath.row, hideTopSeparator: hideTopSeparator)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewItems.isEmpty {
            let contentHeight = delegate?.height(tableView: tableView, except: self) ?? 0
            let height = max(0, tableView.height - tableView.safeAreaInsets.height - contentHeight)

            switch customCell {
            case .none: return 0
            default: return height
            }
        } else {
            switch indexPath.section {
            case 0: return WalletTokenCell.height
            default: return .margin32
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !viewItems.isEmpty, indexPath.section == 0 {
            let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath
            tableView.deselectRow(at: originalIndexPath, animated: true)
            viewModel.didSelect(item: viewItems[indexPath.row])
        }
    }

}

extension WalletTokenListDataSource {

    enum CustomCell {
        case none
        case empty
        case noResults
        case spinner
        case failed
        case invalidApiKey

        var count: Int {
            switch self {
            case .none: return 0
            default: return 1
            }
        }
    }

}
