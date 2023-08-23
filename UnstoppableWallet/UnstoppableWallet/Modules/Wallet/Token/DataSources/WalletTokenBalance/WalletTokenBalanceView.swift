import Foundation
import UIKit
import Combine
import HUD

class WalletTokenBalanceView: NSObject {
    private let viewModel: WalletTokenBalanceViewModel
    private var cancellables: [AnyCancellable] = []

    private let sectionsUpdatedSubject = PassthroughSubject<Void, Never>()

    private var headerViewItem: BalanceTopViewItem?
    private var tableView: UITableView?

    weak var parentViewController: UIViewController?

    init(viewModel: WalletTokenBalanceViewModel) {
        self.viewModel = viewModel

        super.init()

        viewModel.playHapticPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.playHaptic()
                }
                .store(in: &cancellables)

        viewModel.$viewItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.sync(headerViewItem: $0)
                }
                .store(in: &cancellables)

        sync(headerViewItem: viewModel.viewItem)
    }

    private func sync(headerViewItem: BalanceTopViewItem?) {
//        let heightChanged = self.headerViewItem?.buttons.isEmpty != headerViewItem?.buttons.isEmpty

        self.headerViewItem = headerViewItem

        if let headerCell = tableView?.cellForRow(at: IndexPath(row: 0, section: 0)) as? WalletTokenBalanceCell {
            bind(headerCell: headerCell)

//            if heightChanged {
//                tableView?.beginUpdates()
//                tableView?.endUpdates()
//            }
        }
    }

    private func bind(headerCell: WalletTokenBalanceCell) {
        if let headerViewItem {
            headerCell.bind(viewItem: headerViewItem) {
                print("tap error")
            }
        }
    }

    private func bindHeaderActions(cell: WalletTokenBalanceCell) {
//        // Cex actions
//        cell.actions[.deposit] = { [weak self] in
//            if let viewController = CexCoinSelectModule.viewController(mode: .deposit) {
//                self?.parentViewController?.present(viewController, animated: true)
//            }
//        }
//        cell.actions[.withdraw] = { [weak self] in
//            if let viewController = CexCoinSelectModule.viewController(mode: .withdraw) {
//                self?.parentViewController?.present(viewController, animated: true)
//            }
//        }
//        // Decentralized actions
//        cell.actions[.send] = { [weak self] in
//            guard let viewController = WalletModule.sendTokenListViewController() else {
//                return
//            }
//            self?.parentViewController?.present(viewController, animated: true)
//        }
//
//        cell.actions[.swap] = { [weak self] in
//            guard let viewController = WalletModule.swapTokenListViewController() else {
//                return
//            }
//            self?.parentViewController?.present(viewController, animated: true)
//        }
//
//        cell.actions[.receive] = { [weak self] in
//            if let viewController = ReceiveModule.viewController() {
//                self?.parentViewController?.present(viewController, animated: true)
//            }
//        }
    }

    private func playHaptic() {
        HapticGenerator.instance.notification(.feedback(.soft))
    }

}

extension WalletTokenBalanceView: ISectionDataSource {

    func prepare(tableView: UITableView) {
        tableView.registerCell(forClass: WalletTokenBalanceCell.self)
        self.tableView = tableView
    }

    var sectionsUpdatedPublisher: AnyPublisher<(), Never> {
        sectionsUpdatedSubject.eraseToAnyPublisher()
    }

}

extension WalletTokenBalanceView: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WalletTokenBalanceCell.self), for: indexPath)

        if let headerCell = cell as? WalletTokenBalanceCell {
            bindHeaderActions(cell: headerCell)
        }

        return cell
    }

}

extension WalletTokenBalanceView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? WalletTokenBalanceCell {
            bind(headerCell: cell)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        WalletTokenBalanceCell.height(viewItem: headerViewItem)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return .margin12
        }
        return .zero
    }

}
