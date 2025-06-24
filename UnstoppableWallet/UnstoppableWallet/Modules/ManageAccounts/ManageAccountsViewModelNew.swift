import Combine

class ManageAccountsViewModelNew: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let cloudBackupManager = Core.shared.cloudBackupManager
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var regularItems = [Item]()
    @Published private(set) var watchItems = [Item]()

    init() {
        accountManager.activeAccountPublisher
            .sink { [weak self] _ in self?.syncItems() }
            .store(in: &cancellables)

        accountManager.accountsPublisher
            .sink { [weak self] _ in self?.syncItems() }
            .store(in: &cancellables)

        cloudBackupManager.$oneWalletItems
            .sink { [weak self] _ in self?.syncItems() }
            .store(in: &cancellables)

        syncItems()
    }

    private func syncItems() {
        let activeAccount = accountManager.activeAccount

        let items = accountManager.accounts.map { account in
            let cloudBackedUp = cloudBackupManager.backedUp(uniqueId: account.type.uniqueId())
            return Item(account: account, cloudBackedUp: cloudBackedUp, isActive: account == activeAccount)
        }

        let sortedItems = items.sorted { $0.account.name.lowercased() < $1.account.name.lowercased() }

        regularItems = sortedItems.filter { !$0.account.watchAccount }
        watchItems = sortedItems.filter(\.account.watchAccount)
    }
}

extension ManageAccountsViewModelNew {
    var hasAccounts: Bool {
        !accountManager.accounts.isEmpty
    }

    func set(activeAccountId: String) {
        accountManager.set(activeAccountId: activeAccountId)
    }
}

extension ManageAccountsViewModelNew {
    struct Item {
        let account: Account
        let cloudBackedUp: Bool
        let isActive: Bool
    }
}
