import Combine
import MarketKit
import RxRelay
import RxSwift

class ManageAccountService {
    private let accountRelay = PublishRelay<Account>()
    private(set) var account: Account {
        didSet {
            accountRelay.accept(account)
        }
    }

    private let accountManager: AccountManager
    private let cloudBackupManager: CloudBackupManager
    private let passcodeManager: PasscodeManager
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .cannotSave {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let accountDeletedRelay = PublishRelay<Void>()
    private let cloudBackedUpRelay = PublishRelay<Void>()

    private var newName: String

    init?(accountId: String, accountManager: AccountManager, cloudBackupManager: CloudBackupManager, passcodeManager: PasscodeManager) {
        guard let account = accountManager.account(id: accountId) else {
            return nil
        }

        self.account = account
        self.accountManager = accountManager
        self.cloudBackupManager = cloudBackupManager
        self.passcodeManager = passcodeManager

        newName = account.name

        subscribe(disposeBag, accountManager.accountUpdatedObservable) { [weak self] in self?.handleUpdated(account: $0) }
        subscribe(disposeBag, accountManager.accountDeletedObservable) { [weak self] in self?.handleDeleted(account: $0) }

        cloudBackupManager.$oneWalletItems
            .sink { [weak self] _ in
                self?.cloudBackedUpRelay.accept(())
            }
            .store(in: &cancellables)

        syncState()
    }

    private func syncState() {
        if !newName.isEmpty, account.name != newName {
            state = .canSave
        } else {
            state = .cannotSave
        }
    }

    private func handleUpdated(account: Account) {
        if account.id == self.account.id {
            self.account = account
        }
    }

    private func handleDeleted(account: Account) {
        if account.id == self.account.id {
            accountDeletedRelay.accept(())
        }
    }
}

extension ManageAccountService {
    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var accountObservable: Observable<Account> {
        accountRelay.asObservable()
    }

    var accountDeletedObservable: Observable<Void> {
        accountDeletedRelay.asObservable()
    }

    var cloudBackedUpObservable: Observable<Void> {
        cloudBackedUpRelay.asObservable()
    }

    var isCloudBackedUp: Bool {
        cloudBackupManager.backedUp(uniqueId: account.type.uniqueId())
    }

    var isPasscodeSet: Bool {
        passcodeManager.isPasscodeSet
    }

    func set(name: String) {
        newName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        syncState()
    }

    func saveAccount() {
        account.name = newName
        accountManager.update(account: account)
    }

    func deleteCloudBackup() throws {
        try cloudBackupManager.delete(uniqueId: account.type.uniqueId())
    }
}

extension ManageAccountService {
    enum State {
        case cannotSave
        case canSave
    }
}
