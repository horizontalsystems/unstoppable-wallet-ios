import Foundation
import RxSwift
import RxRelay

class MainService {
    private let localStorage: ILocalStorage
    private let accountManager: IAccountManager
    private let disposeBag = DisposeBag()

    private let hasAccountsRelay = PublishRelay<Bool>()
    private(set) var hasAccounts: Bool = false {
        didSet {
            if oldValue != hasAccounts {
                hasAccountsRelay.accept(hasAccounts)
            }
        }
    }

    init(localStorage: ILocalStorage, accountManager: IAccountManager) {
        self.localStorage = localStorage
        self.accountManager = accountManager

        subscribe(disposeBag, accountManager.accountsObservable) { [weak self] in self?.sync(accounts: $0) }

        sync(accounts: accountManager.accounts)
    }

    private func sync(accounts: [Account]) {
        hasAccounts = !accounts.isEmpty
    }

}

extension MainService {

    var hasAccountsObservable: Observable<Bool> {
        hasAccountsRelay.asObservable()
    }

    func setMainShownOnce() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.localStorage.mainShownOnce = true
        }
    }

}
