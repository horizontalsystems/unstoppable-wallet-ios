import Foundation

class AddErc20TokenPresenter {
    weak var view: IAddErc20TokenView?

    private let interactor: IAddErc20TokenInteractor
    private let router: IAddErc20TokenRouter

    private var coin: Coin?

    init(interactor: IAddErc20TokenInteractor, router: IAddErc20TokenRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func viewItem(coin: Coin) -> AddErc20TokenModule.ViewItem {
        AddErc20TokenModule.ViewItem(coinName: coin.title, symbol: coin.code, decimals: coin.decimal)
    }

}

extension AddErc20TokenPresenter: IAddErc20TokenViewDelegate {

    func onChange(address: String?) {
        guard let address = address, !address.isEmpty else {
            view?.set(error: nil)
            view?.set(spinnerVisible: false)
            view?.set(viewItem: nil)
            view?.set(warningVisible: false)
            view?.set(buttonVisible: false)

            view?.refresh()

            return
        }

        do {
            try interactor.validate(address: address)
            view?.set(error: nil)
        } catch {
            view?.set(error: error.convertedError)

            view?.refresh()
            return
        }

        if let coin = interactor.existingCoin(address: address) {
            view?.set(viewItem: viewItem(coin: coin))
            view?.set(warningVisible: true)

            view?.refresh()
            return
        }

        view?.set(spinnerVisible: true)

        view?.refresh()

        interactor.fetchCoin(address: address)
    }

    func onTapAddButton() {
        guard let coin = coin else {
            return
        }

        interactor.save(coin: coin)

        view?.showSuccess()
        router.close()
    }

    func onTapCancel() {
        router.close()
    }

}

extension AddErc20TokenPresenter: IAddErc20TokenInteractorDelegate {

    func didFetch(coin: Coin) {
        self.coin = coin

        view?.set(spinnerVisible: false)
        view?.set(viewItem: viewItem(coin: coin))
        view?.set(buttonVisible: true)

        view?.refresh()
    }

    func didFailToFetchCoin(error: Error) {
        view?.set(error: error)
        view?.set(spinnerVisible: false)

        view?.refresh()
    }

}
