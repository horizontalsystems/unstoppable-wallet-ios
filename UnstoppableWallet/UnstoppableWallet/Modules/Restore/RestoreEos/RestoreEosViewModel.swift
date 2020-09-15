import RxSwift
import RxRelay
import RxCocoa

class RestoreEosViewModel {
    private let service: RestoreEosService

    private let accountTypeRelay = PublishRelay<AccountType>()
    private let errorRelay = PublishRelay<Error>()

    private(set) var account: String
    private(set) var privateKey: String

    init(service: RestoreEosService) {
        self.service = service

        account = service.defaultAccount
        privateKey = service.defaultPrivateKey
    }

    var accountTypeSignal: Signal<AccountType> {
        accountTypeRelay.asSignal()
    }

    var errorSignal: Signal<Error> {
        errorRelay.asSignal()
    }

    func onEnter(account: String) {
        self.account = account
    }

    func onEnter(privateKey: String) {
        self.privateKey = privateKey
    }

    func onProceed() {
        do {
            let accountType = try service.accountType(account: account, privateKey: privateKey)
            accountTypeRelay.accept(accountType)
        } catch {
            errorRelay.accept(error.convertedError)
        }
    }

}
