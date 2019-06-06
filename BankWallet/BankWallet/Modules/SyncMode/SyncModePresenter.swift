class SyncModePresenter {
    weak var view: ISyncModeView?

    private let interactor: ISyncModeInteractor
    private let router: ISyncModeRouter
    private var state: SyncModeState
    private let mode: SyncModuleStartMode

    init(interactor: ISyncModeInteractor, router: ISyncModeRouter, state: SyncModeState, mode: SyncModuleStartMode) {
        self.interactor = interactor
        self.router = router
        self.state = state
        self.mode = mode
    }

}

extension SyncModePresenter: ISyncModeViewDelegate {

    func onSelectFast() {
        state.mode = .fast
    }

    func onSelectSlow() {
        state.mode = .slow
    }

    func onDone() {
        router.showAgreement()
    }

}

extension SyncModePresenter: ISyncModeInteractorDelegate {

    func didRestore() {
        router.navigateToSetPin()
    }

    func didFailToRestore(withError error: Error) {
        view?.showInvalidWordsError()
    }

    func didConfirmAgreement() {
        if case let .initial(words) = mode {
            interactor.restore(with: words, syncMode: state.mode)
        } else {
            interactor.reSync(syncMode: state.mode)
        }
    }

}
