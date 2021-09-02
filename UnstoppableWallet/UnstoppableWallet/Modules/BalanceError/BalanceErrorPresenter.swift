import UIKit
import MarketKit

class BalanceErrorPresenter {
    weak var view: IBalanceErrorView?

    private let interactor: IBalanceErrorInteractor
    private let router: IBalanceErrorRouter

    private let wallet: WalletNew
    private let error: Error

    init(wallet: WalletNew, error: Error, interactor: IBalanceErrorInteractor, router: IBalanceErrorRouter) {
        self.wallet = wallet
        self.error = error

        self.interactor = interactor
        self.router = router
    }

    private func isSourceChangeable(coinType: CoinType) -> Bool {
        switch coinType {
        case .ethereum, .erc20, .bep2: return false
        default: return true
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
        router.closeAndOpenPrivacySettings()
    }

    func onTapReport() {
        view?.openReport(email: interactor.contactEmail, error: "\(error)")
    }

    func onTapClose() {
        router.close()
    }

}
