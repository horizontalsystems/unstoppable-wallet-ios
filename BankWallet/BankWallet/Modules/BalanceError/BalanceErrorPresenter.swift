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

    private var errorText: String {
        error.localizedDescription
    }

}

extension BalanceErrorPresenter: IBalanceErrorViewDelegate {

    func onLoad() {
        view?.set(coinTitle: wallet.coin.title)

        var buttonTypes = [BalanceErrorModule.Buttons]()
        buttonTypes.append(.retry)

        let adapter = interactor.adapter(for: wallet)
        if !(adapter is BinanceAdapter || adapter is EosAdapter) {
            buttonTypes.append(.changeSource)
        }

        view?.set(buttons: buttonTypes)

        interactor.copyToClipboard(text: "\(error)")
    }

    func onTapRetry() {
        interactor.refresh(wallet: wallet)

        router.close()
    }

    func onTapChangeSource() {
        router.openPrivacySettings()

        router.close()
    }

    func onTapReport() {
        interactor.copyToClipboard(text: "\(error)")

        router.openReport()
        router.close()
    }

    func onTapClose() {
        router.close()
    }

}
