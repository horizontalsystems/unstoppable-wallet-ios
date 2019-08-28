import Foundation

class SendAccountPresenter {
    weak var view: ISendAccountView?
    weak var delegate: ISendAccountDelegate?

    private let interactor: ISendAccountInteractor
    private let router: ISendAccountRouter

    var currentAccount: String? {
        didSet {
            delegate?.onUpdateAccount()
        }
    }

    init(interactor: ISendAccountInteractor, router: ISendAccountRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func onEnter(account: String) {
        do {
            try delegate?.validate(account: account)

            view?.set(account: account, error: nil)
            self.currentAccount = account
        } catch {
            view?.set(account: account, error: error)
            self.currentAccount = nil
        }
    }

    private func onClear() {
        view?.set(account: nil, error: nil)
        currentAccount = nil
    }

}

extension SendAccountPresenter: ISendAccountViewDelegate {

    func onScanClicked() {
        router.scanQrCode(delegate: self)
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

    func validAccount() throws -> String {
        guard let validAccount = currentAccount else {
            throw ValidationError.invalidAccount
        }

        return validAccount
    }

}

extension SendAccountPresenter: IScanQrCodeDelegate {

    func didScan(string: String) {
        onEnter(account: string)
    }

}

extension SendAccountPresenter {

    private enum ValidationError: LocalizedError {
        case invalidAccount

        var errorDescription: String? {
            switch self {
            case .invalidAccount:
                return "send.account_error.invalid_account".localized
            }
        }
    }

}
