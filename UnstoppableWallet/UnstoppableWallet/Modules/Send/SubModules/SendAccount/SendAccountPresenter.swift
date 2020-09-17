import UIKit

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

            view?.set(error: nil)
            self.currentAccount = account
        } catch {
            view?.set(error: error)
            self.currentAccount = nil
        }
    }

}

extension SendAccountPresenter: ISendAccountViewDelegate {

    func onOpenScan(controller: UIViewController) {
        router.openScanQrCode(controller: controller)
    }

    func onChange(account: String?) {
        guard let account = account, !account.isEmpty else {
            currentAccount = nil
            view?.set(error: nil)
            return
        }
        onEnter(account: account)
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
