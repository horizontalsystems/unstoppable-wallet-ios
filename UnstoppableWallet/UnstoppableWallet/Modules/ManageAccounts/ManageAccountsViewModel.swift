import Combine

class ManageAccountsViewModel: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let cloudBackupManager = Core.shared.cloudBackupManager
    private var cancellables = Set<AnyCancellable>()

    @Published var filter: String = "" {
        didSet { sync() }
    }

    @Published private(set) var sections = [Section]()

    init() {
        accountManager.activeAccountPublisher
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)

        accountManager.accountsPublisher
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)

        cloudBackupManager.$oneWalletItems
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)

        sync()
    }

    private func sync() {
        let activeAccount = accountManager.activeAccount
        let allAccounts = accountManager.accounts

        let trimmed = filter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let mapped = allAccounts
            .filter { trimmed.isEmpty || $0.name.lowercased().contains(trimmed) }
            .map { account in
                let cloudBackedUp = cloudBackupManager.backedUp(uniqueId: account.type.uniqueId())
                return Item(account: account, cloudBackedUp: cloudBackedUp, isActive: account == activeAccount)
            }

        let regular = mapped.filter { !$0.account.watchAccount }
            .sorted { $0.account.name.lowercased() < $1.account.name.lowercased() }
        let watch = mapped.filter(\.account.watchAccount)
            .sorted { $0.account.name.lowercased() < $1.account.name.lowercased() }

        var sections = [Section]()
        if !regular.isEmpty {
            sections.append(Section(kind: .wallets, items: regular))
        }
        if !watch.isEmpty {
            sections.append(Section(kind: .watchWallets, items: watch))
        }
        self.sections = sections
    }
}

extension ManageAccountsViewModel {
    var hasAccounts: Bool {
        !accountManager.accounts.isEmpty
    }

    func set(activeAccountId: String) {
        accountManager.set(activeAccountId: activeAccountId)
    }
}

extension ManageAccountsViewModel {
    struct Item: Hashable {
        let account: Account
        let cloudBackedUp: Bool
        let isActive: Bool

        func hash(into hasher: inout Hasher) {
            hasher.combine(account)
            hasher.combine(isActive)
        }
    }

    struct Section: Identifiable, Hashable {
        let kind: Kind
        let items: [Item]

        var id: Kind { kind }

        var title: String {
            switch kind {
            case .wallets: return "switch_account.wallets".localized
            case .watchWallets: return "switch_account.watch_wallets".localized
            }
        }
    }

    enum Kind: Hashable {
        case wallets
        case watchWallets
    }
}
