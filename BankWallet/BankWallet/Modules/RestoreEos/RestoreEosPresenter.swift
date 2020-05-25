class RestoreEosPresenter {
    weak var view: IRestoreEosView?

    private let handler: IRestoreAccountTypeHandler
    private let interactor: IRestoreEosInteractor

    private var state: RestoreEosPresenterState

    init(handler: IRestoreAccountTypeHandler, interactor: IRestoreEosInteractor, state: RestoreEosPresenterState) {
        self.handler = handler
        self.interactor = interactor
        self.state = state
    }

    private func onEnter(account: String?) {
        state.account = account
        view?.set(account: account)
    }

    private func onEnter(key: String?) {
        state.privateKey = key
        view?.set(key: key)
    }

    private func omitReturns(string: String) -> String {
        string.replacingOccurrences(of: "\n", with: " ")
    }

}

extension RestoreEosPresenter: IRestoreEosViewDelegate {

    func viewDidLoad() {
        if handler.selectCoins {
            view?.showNextButton()
        } else {
            view?.showRestoreButton()
        }

        let (account, activePrivateKey) = interactor.defaultCredentials
        onEnter(account: account)
        onEnter(key: activePrivateKey)
    }

    func onPasteAccountClicked() {
        if let account = interactor.valueFromPasteboard {
            onEnter(account: omitReturns(string: account))
        }
    }

    func onChange(account: String?) {
        onEnter(account: account)
    }

    func onDeleteAccount() {
        onEnter(account: nil)
    }

    func onPasteKeyClicked() {
        if let key = interactor.valueFromPasteboard {
            onEnter(key: omitReturns(string: key))
        }
    }

    func onDeleteKey() {
        onEnter(key: nil)
    }

    func didTapCancel() {
        handler.handleCancel()
    }

    func didTapDone() {
        let account = (state.account ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        let privateKey = (state.privateKey ?? "").trimmingCharacters(in: .whitespaces)

        do {
            try interactor.validate(account: account)
            try interactor.validate(privateKey: privateKey)

            let accountType: AccountType = .eos(account: account, activePrivateKey: privateKey)

            handler.handle(accountType: accountType)
        } catch {
            view?.show(error: error.convertedError)
        }
    }

    func didTapScanQr() {
        handler.handleScanQr(delegate: self)
    }

}

extension RestoreEosPresenter: IScanQrModuleDelegate {

    func didScan(string: String) -> ScanQrModule.Result {
        onEnter(key: string)
        return .success
    }

}

extension RestoreEosPresenter: IRestoreEosInteractorDelegate {
}
