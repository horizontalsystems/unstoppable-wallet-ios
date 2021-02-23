import UIKit
import CoinKit

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
        case .ethereum, .erc20, .bep2: return false
        default: return true
        }
    }

}

extension BalanceErrorPresenter: IBalanceErrorViewDelegate {

    func onLoad() {
        view?.set(coinTitle: wallet.coin.title)
        view?.setChangeSourceButton(hidden: !isSourceChangeable(coinType: wallet.coin.type))
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
