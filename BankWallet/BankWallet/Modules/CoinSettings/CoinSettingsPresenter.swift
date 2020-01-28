class CoinSettingsPresenter {
    weak var view: ICoinSettingsView?

    private let proceedMode: RestoreRouter.ProceedMode
    private let router: ICoinSettingsRouter
    private let interactor: ICoinSettingsInteractor

    init(proceedMode: RestoreRouter.ProceedMode, router: ICoinSettingsRouter, interactor: ICoinSettingsInteractor) {
        self.proceedMode = proceedMode
        self.router = router
        self.interactor = interactor
    }

}

extension CoinSettingsPresenter: ICoinSettingsViewDelegate {

    func onLoad() {
        if proceedMode == .next {
            view?.showNextButton()
        } else {
            view?.showRestoreButton()
        }

        view?.set(derivation: interactor.bitcoinDerivation)
        view?.set(syncMode: interactor.syncMode)
    }

    func onSelect(derivation: MnemonicDerivation) {
        interactor.bitcoinDerivation = derivation
    }

    func onSelect(syncMode: SyncMode) {
        interactor.syncMode = syncMode
    }

    func onTapNextButton() {
        router.notifySelected()
    }

}
