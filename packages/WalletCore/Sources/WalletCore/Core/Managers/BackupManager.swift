import Combine
import HsExtensions
import RxRelay
import RxSwift

class BackupManager {
    private let accountManager: AccountManager
    private var cancellables = Set<AnyCancellable>()

    private let allBackedUpRelay = PublishRelay<Bool>()

    init(accountManager: AccountManager) {
        self.accountManager = accountManager

        accountManager.accountsPublisher
            .sink { [weak self] _ in self?.updateAllBackedUp() }
            .store(in: &cancellables)
    }

    private func updateAllBackedUp() {
        allBackedUpRelay.accept(allBackedUp)
    }
}

extension BackupManager {
    var allBackedUp: Bool {
        accountManager.accounts.allSatisfy(\.backedUp)
    }

    var allBackedUpObservable: Observable<Bool> {
        allBackedUpRelay.asObservable()
    }

    func setAccountBackedUp(id: String) {
        guard let account = accountManager.account(id: id) else {
            return
        }

        account.backedUp = true
        accountManager.update(account: account)
    }
}
