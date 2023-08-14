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

        viewModel.showZcashRestoreSelectPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] token in
                    self?.showZcashRestoreSelect(token: token)
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
        guard let viewController = ReceiveAddressModule.viewController(wallet: wallet) else {
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

    private func showZcashRestoreSelect(token: Token) {
        let viewController = BottomSheetModule.viewController(
                image: .remote(url: token.coin.imageUrl, placeholder: "placeholder_circle_32"),
                title: token.coin.code,
                subtitle: token.coin.name,
                items: [
                    .description(text: "deposit.zcash.restore.description".localized)
                ],
                buttons: [
                    .init(style: .yellow, title: "deposit.zcash.restore.already_own".localized, actionType: .afterClose, action: { [weak self] in
                        self?.showRestoreZcash(token: token)
                    }),
                    .init(style: .gray, title: "deposit.zcash.restore.dont_have".localized, actionType: .afterClose, action: { [weak self] in
                        self?.viewModel.onRestoreZcash(token: token, height: nil)
                    }),
                ])

        present(viewController, animated: true)
    }

    private func showBlockchainSelect(fullCoin: FullCoin, accountType: AccountType) {
        let viewController = ReceiveModule.selectTokenViewController(fullCoin: fullCoin, accountType: accountType) { [weak self] token in
            self?.onSelectExact(token: token)
        }
        pushViewController(viewController, animated: true)
    }

    private func showRestoreZcash(token: Token) {
        let viewController = BirthdayInputViewController(token: token)
        viewController.onEnterBirthdayHeight = { [weak self] height in
            self?.viewModel.onRestoreZcash(token: token, height: height)
        }
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
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
