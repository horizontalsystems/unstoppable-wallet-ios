import Combine
import UIKit
import ThemeKit
import MarketKit

class ReceiveViewController: ThemeNavigationController {
    private let viewModel: ReceiveViewModel
    private var cancellables = [AnyCancellable]()

    init(rootViewController: ReceiveSelectCoinViewController, viewModel: ReceiveViewModel) {
        self.viewModel = viewModel
        super.init(rootViewController: rootViewController)

        rootViewController.onSelect = { [weak self] fullCoin in
            self?.onSelect(fullCoin: fullCoin)
        }

        viewModel.showTokenPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] wallet in
                    self?.showReceive(wallet: wallet)
                }
                .store(in: &cancellables)

        viewModel.showDerivationSelectPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] wallets in
                    self?.showDerivationSelect(wallets: wallets)
                }
                .store(in: &cancellables)

        viewModel.showBitcoinCashCoinTypeSelectPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] wallets in
                    self?.showBitcoinCashCoinTypeSelect(wallets: wallets)
                }
                .store(in: &cancellables)

        viewModel.showBlockchainSelectPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (fullCoin, accountType) in
                    self?.showBlockchainSelect(fullCoin: fullCoin, accountType: accountType)
                }
                .store(in: &cancellables)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showReceive(wallet: Wallet) {
        guard let viewController = DepositModule.viewController(wallet: wallet) else {
            return
        }
        pushViewController(viewController, animated: true)
    }

    private func showDerivationSelect(wallets: [Wallet]) {
        let viewController = ReceiveModule.selectDerivationViewController(wallets: wallets) { [weak self] wallet in
            self?.showReceive(wallet: wallet)
        }
        pushViewController(viewController, animated: true)
    }

    private func showBitcoinCashCoinTypeSelect(wallets: [Wallet]) {
        let viewController = ReceiveModule.selectBitcoinCashCoinTypeViewController(wallets: wallets) { [weak self] wallet in
            self?.showReceive(wallet: wallet)
        }
        pushViewController(viewController, animated: true)
    }

    private func showBlockchainSelect(fullCoin: FullCoin, accountType: AccountType) {
        let viewController = ReceiveModule.selectTokenViewController(fullCoin: fullCoin, accountType: accountType) { [weak self] token in
            self?.onSelectExact(token: token)
        }
        pushViewController(viewController, animated: true)
    }

}

extension ReceiveViewController {

    func onSelect(fullCoin: FullCoin) {
        viewModel.onSelect(fullCoin: fullCoin)
    }

    func onSelectExact(token: Token) {
        viewModel.onSelectExact(token: token)
    }

}
