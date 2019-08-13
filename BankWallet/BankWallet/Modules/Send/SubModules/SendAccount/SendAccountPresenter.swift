class SendAccountPresenter {
    weak var view: ISendAccountView?
    weak var delegate: ISendAccountDelegate?

    private let interactor: ISendAccountInteractor

    var account: String? {
        didSet {
            delegate?.onUpdateAccount()
        }
    }

    init(interactor: ISendAccountInteractor) {
        self.interactor = interactor
    }

    private func onEnter(account: String) {
        do {
            try delegate?.validate(account: account)

            view?.set(account: account, error: nil)
            self.account = account
        } catch {
            view?.set(account: account, error: error.localizedDescription)
            self.account = nil
        }
    }

    private func onClear() {
        view?.set(account: nil, error: nil)
        account = nil
    }

}

extension SendAccountPresenter: ISendAccountViewDelegate {

    func onScanClicked() {
        delegate?.scanQrCode(delegate: self)
    }

    func onPasteClicked() {
        if let account = interactor.valueFromPasteboard {
            onEnter(account: account)
        }
    }

    func onChange(account: String?) {
        guard let account = account, !account.isEmpty else {
            onClear()
            return
        }
        onEnter(account: account)
    }

    func onDeleteClicked() {
        onClear()
    }

}

extension SendAccountPresenter: ISendAccountModule {
}

extension SendAccountPresenter: IScanQrCodeDelegate {

    func didScan(string: String) {
        onEnter(account: string)
    }

}
