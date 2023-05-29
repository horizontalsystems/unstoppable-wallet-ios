import RxSwift
import RxRelay
import MarketKit
import PinKit
import Combine

class ManageAccountService {
    private let accountRelay = PublishRelay<Account>()
    private(set) var account: Account {
        didSet {
            accountRelay.accept(account)
        }
    }

    private let accountManager: AccountManager
    private let cloudBackupManager: CloudAccountBackupManager
    private let pinKit: PinKit.Kit
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .cannotSave {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let accountDeletedRelay = PublishRelay<()>()
    private let cloudBackedUpRelay = PublishRelay<()>()

    private var newName: String

    init?(accountId: String, accountManager: AccountManager, cloudBackupManager: CloudAccountBackupManager, pinKit: PinKit.Kit) {
        guard let account = accountManager.account(id: accountId) else {
            return nil
        }

        self.account = account
        self.accountManager = accountManager
        self.cloudBackupManager = cloudBackupManager

        self.pinKit = pinKit

        newName = account.name

        subscribe(disposeBag, accountManager.accountUpdatedObservable) { [weak self] in self?.handleUpdated(account: $0) }
        subscribe(disposeBag, accountManager.accountDeletedObservable) { [weak self] in self?.handleDeleted(account: $0) }

        cloudBackupManager.$items
                .sink { [weak self] _ in
                    self?.cloudBackedUpRelay.accept(())
                }
                .store(in: &cancellables)

        syncState()
    }

    private func syncState() {
        if !newName.isEmpty && account.name != newName {
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

    var accountDeletedObservable: Observable<()> {
        accountDeletedRelay.asObservable()
    }

    var cloudBackedUpObservable: Observable<()> {
        cloudBackedUpRelay.asObservable()
    }

    var isCloudBackedUp: Bool {
        cloudBackupManager.backedUp(uniqueId: account.type.uniqueId())
    }

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    func set(name: String) {
        newName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        syncState()
    }

    func saveAccount() {
        account.name = newName
        accountManager.update(account: account)
    }

    func deleteCloudBackup() async throws {
        try await cloudBackupManager.delete(uniqueId: account.type.uniqueId())
    }

}

extension ManageAccountService {

    enum State {
        case cannotSave
        case canSave
    }

}
