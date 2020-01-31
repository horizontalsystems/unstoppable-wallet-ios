class BlockchainSettingsPresenter {
    weak var view: IBlockchainSettingsView?

    private let proceedMode: RestoreRouter.ProceedMode
    private let router: IBlockchainSettingsRouter
    private let interactor: IBlockchainSettingsInteractor

    private var selectedDerivation: MnemonicDerivation
    private var selectedSyncMode: SyncMode

    init(proceedMode: RestoreRouter.ProceedMode, router: IBlockchainSettingsRouter, interactor: IBlockchainSettingsInteractor) {
        self.proceedMode = proceedMode
        self.router = router
        self.interactor = interactor

        selectedDerivation = interactor.bitcoinDerivation
        selectedSyncMode = interactor.syncMode
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
        if selectedDerivation != derivation, !interactor.walletsForDerivationUpdate.isEmpty {
            view?.showChangeAlert(derivation: derivation)
        } else {
            interactor.bitcoinDerivation = derivation
            view?.set(derivation: derivation)
        }
    }

    func onSelect(syncMode: SyncMode) {
        if selectedSyncMode != syncMode, !interactor.walletsForSyncModeUpdate.isEmpty {
            view?.showChangeAlert(syncMode: syncMode)
        } else {
            interactor.syncMode = syncMode
            view?.set(syncMode: syncMode)
        }
    }

    func onConfirm() {
        router.notifyConfirm()
    }

    func proceedChange(derivation: MnemonicDerivation) {
        selectedDerivation = derivation
        view?.set(derivation: derivation)

        interactor.bitcoinDerivation = derivation
        interactor.update(derivation: derivation, in: interactor.walletsForDerivationUpdate)
    }

    func proceedChange(syncMode: SyncMode) {
        selectedSyncMode = syncMode
        view?.set(syncMode: syncMode)

        interactor.syncMode = syncMode
        interactor.update(syncMode: syncMode, in: interactor.walletsForSyncModeUpdate)
    }

}
