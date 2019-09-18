class RestoreOptionsPresenter {
    weak var view: IRestoreOptionsView?

    private let router: IRestoreOptionsRouter

    private var syncMode: SyncMode = .fast
    private var derivation: MnemonicDerivation = .bip44

    init(router: IRestoreOptionsRouter) {
        self.router = router
    }

}

extension RestoreOptionsPresenter: IRestoreOptionsViewDelegate {

    func viewDidLoad() {
        view?.set(syncMode: syncMode)
        view?.set(derivation: derivation)
    }

    func didTapDoneButton() {
        router.notifyDelegate(syncMode: syncMode, derivation: derivation)
    }

    func onTapFastSync() {
        syncMode = .fast
        view?.set(syncMode: syncMode)
    }

    func onTapSlowSync() {
        syncMode = .slow
        view?.set(syncMode: syncMode)
    }

    func onTapBeforeUpdate() {
        derivation = .bip44
        view?.set(derivation: derivation)
    }

    func onTapAfterUpdate() {
        derivation = .bip49
        view?.set(derivation: derivation)
    }

}
