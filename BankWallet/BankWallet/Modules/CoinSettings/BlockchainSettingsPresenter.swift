class BlockchainSettingsPresenter {
    weak var view: IBlockchainSettingsView?

    private let proceedMode: RestoreRouter.ProceedMode
    private let router: IBlockchainSettingsRouter
    private let interactor: IBlockchainSettingsInteractor

    init(proceedMode: RestoreRouter.ProceedMode, router: IBlockchainSettingsRouter, interactor: IBlockchainSettingsInteractor) {
        self.proceedMode = proceedMode
        self.router = router
        self.interactor = interactor
    }

}

extension BlockchainSettingsPresenter: IBlockchainSettingsViewDelegate {

    func onLoad() {
        switch proceedMode {
        case .next:
            view?.showNextButton()
        case .restore:
            view?.showRestoreButton()
        case .none: ()
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

    func onConfirm() {
        router.notifyConfirm()
    }

}
