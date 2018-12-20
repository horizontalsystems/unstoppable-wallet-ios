import Foundation

class ManageCoinsPresenter {

    private let interactor: IManageCoinsInteractor
    private let router: IManageCoinsRouter
    private var state: IManageCoinsPresenterState

    weak var view: IManageCoinsView?

    init(interactor: IManageCoinsInteractor, router: IManageCoinsRouter, state: IManageCoinsPresenterState) {
        self.interactor = interactor
        self.router = router
        self.state = state
    }

    private func updateCoins() {
        view?.showCoins(enabled: state.enabledCoins, disabled: state.disabledCoins)
    }

}

extension ManageCoinsPresenter: IManageCoinsInteractorDelegate {

    func didLoadCoins(all: [Coin], enabled: [Coin]) {
        state.allCoins = all
        state.enabledCoins = enabled
        updateCoins()
    }

    func didSaveCoins() {
        router.close()
    }

    func didFailToSaveCoins() {
        view?.show(error: "manage_coins.fail_to_save")
    }

}

extension ManageCoinsPresenter: IManageCoinsViewDelegate {

    func viewDidLoad() {
        interactor.loadCoins()
    }

    func enable(coin: Coin) {
        state.enable(coin: coin)
        updateCoins()
    }

    func disable(coin: Coin) {
        state.disable(coin: coin)
        updateCoins()
    }

    func move(coin: Coin, to index: Int) {
        state.move(coin: coin, to: index)
        updateCoins()
    }

    func saveChanges() {
        interactor.save(enabledCoins: state.enabledCoins)
        router.close()
    }

}
