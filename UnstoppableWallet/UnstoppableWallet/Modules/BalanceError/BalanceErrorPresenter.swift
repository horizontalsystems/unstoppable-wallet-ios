import UIKit

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
        case .binance, .eos: return false
        default: return true
        }
    }

}

extension BalanceErrorPresenter: IBalanceErrorViewDelegate {

    func onLoad() {
        view?.set(coinTitle: wallet.coin.title)

        view?.setChangeSourceButton(hidden: !isSourceChangeable(coinType: wallet.coin.type))

        interactor.copyToClipboard(text: "\(error)")
    }

    func onTapRetry() {
        interactor.refresh(wallet: wallet)

        router.close()
    }

    func onTapChangeSource() {
        router.closeAndOpenPrivacySettings()
    }

    func onTapReport() {
        interactor.copyToClipboard(text: "\(error)")

        router.closeAndOpenReport()
    }

    func onTapClose() {
        router.close()
    }

}
