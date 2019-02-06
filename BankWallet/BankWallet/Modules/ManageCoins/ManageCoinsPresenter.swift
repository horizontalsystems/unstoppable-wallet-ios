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

}

extension ManageCoinsPresenter: IManageCoinsInteractorDelegate {

    func didLoad(allCoins: [Coin]) {
        state.allCoins = allCoins
        view?.updateUI()
    }

    func didLoad(enabledCoins: [Coin]) {
        state.enabledCoins = enabledCoins
        view?.updateUI()
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
        interactor.syncCoins()
        interactor.loadCoins()
    }

    func enable(atIndex index: Int) {
        state.enable(coin: state.disabledCoins[index])
        view?.updateUI()
    }

    func disable(atIndex index: Int) {
        state.disable(coin: state.enabledCoins[index])
        view?.updateUI()
    }

    func move(from fromIndex: Int, to toIndex: Int) {
        state.move(coin: state.enabledCoins[fromIndex], to: toIndex)
        view?.updateUI()
    }

    func saveChanges() {
        interactor.save(enabledCoins: state.enabledCoins)
    }

    var enabledCoinsCount: Int {
        get {
            return state.enabledCoins.count
        }
    }
    var disabledCoinsCount: Int {
        get {
            return state.disabledCoins.count
        }
    }

    func enabledItem(forIndex index: Int) -> Coin {
        return state.enabledCoins[index]
    }

    func disabledItem(forIndex index: Int) -> Coin {
        return state.disabledCoins[index]
    }

    func onClose() {
        router.close()
    }

}
