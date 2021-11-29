import UIKit
import MarketKit

class BalanceErrorPresenter {
    weak var view: IBalanceErrorView?

    private let interactor: IBalanceErrorInteractor
    private let router: IBalanceErrorRouter

    private let wallet: Wallet
    private let error: Error

    init(wallet: Wallet, error: Error, interactor: IBalanceErrorInteractor, router: IBalanceErrorRouter) {
        self.wallet = wallet
        self.error = error

        self.interactor = interactor
        self.router = router
    }

    private func isSourceChangeable(coinType: CoinType) -> Bool {
        switch coinType {
        case .bitcoin, .bitcoinCash, .dash, .litecoin, .ethereum, .erc20, .binanceSmartChain, .bep20: return true
        default: return false
        }
    }

}

extension BalanceErrorPresenter: IBalanceErrorViewDelegate {

    func onLoad() {
        view?.set(coinTitle: wallet.coin.name)
        view?.setChangeSourceButton(hidden: !isSourceChangeable(coinType: wallet.coinType))
    }

    func onTapRetry() {
        interactor.refresh(wallet: wallet)

        router.close()
    }

    func onTapChangeSource() {
        switch wallet.coinType {
        case .bitcoin, .bitcoinCash, .dash, .litecoin:
            router.closeAndOpenPrivacySettings()
        case .ethereum, .erc20:
            router.closeAndEvmNetwork(blockchain: .ethereum, account: wallet.account)
        case .binanceSmartChain, .bep20:
            router.closeAndEvmNetwork(blockchain: .binanceSmartChain, account: wallet.account)
        default:
            ()
        }
    }

    func onTapReport() {
        view?.openReport(email: interactor.contactEmail, error: "\(error)")
    }

    func onTapClose() {
        router.close()
    }

}
