import RxSwift
import RxRelay

class ManageAccountService {
    private let accountRelay = PublishRelay<Account>()
    private(set) var account: Account {
        didSet {
            accountRelay.accept(account)
        }
    }

    private let accountManager: IAccountManager
    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .cannotSave {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let accountDeletedRelay = PublishRelay<()>()

    private var newName: String

    init?(accountId: String, accountManager: IAccountManager) {
        guard let account = accountManager.account(id: accountId) else {
            return nil
        }

        self.account = account
        self.accountManager = accountManager

        newName = account.name

        subscribe(disposeBag, accountManager.accountsObservable) { [weak self] in self?.handleUpdated(accounts: $0) }

        syncState()
    }

    private func syncState() {
        if !newName.isEmpty && account.name != newName {
            state = .canSave
        } else {
            state = .cannotSave
        }
    }

    private func handleUpdated(accounts: [Account]) {
        guard let account = accounts.first(where: { $0 == account }) else {
            accountDeletedRelay.accept(())
            return
        }

        self.account = account
    }

}

extension ManageAccountService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var accountObservable: Observable<Account> {
        accountRelay.asObservable()
    }

    var accountDeletedObservable: Observable<()> {
        accountDeletedRelay.asObservable()
    }

    func set(name: String) {
        newName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        syncState()
    }

    func saveAccount() {
        account.name = newName
        accountManager.update(account: account)
    }

}

extension ManageAccountService {

    enum State {
        case cannotSave
        case canSave
    }

}
