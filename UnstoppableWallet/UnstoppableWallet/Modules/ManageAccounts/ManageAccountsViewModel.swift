import Combine

class ManageAccountsViewModel: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let cloudBackupManager = Core.shared.cloudBackupManager
    private var cancellables = Set<AnyCancellable>()

    @Published var filter: String = "" {
        didSet { sync() }
    }

    @Published var accountFilter: AccountFilter = .all {
        didSet { sync() }
    }

    @Published private(set) var items = [Item]()
    @Published private(set) var availableFilters: [AccountFilter] = [.all]

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

        var filters: [AccountFilter] = [.all]
        if allAccounts.contains(where: { AccountFilter.mnemonic.matches(account: $0) }) {
            filters.append(.mnemonic)
        }
        if allAccounts.contains(where: { AccountFilter.privateKey.matches(account: $0) }) {
            filters.append(.privateKey)
        }
        if allAccounts.contains(where: { AccountFilter.watch.matches(account: $0) }) {
            filters.append(.watch)
        }
        availableFilters = filters

        let trimmed = filter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let mapped = allAccounts
            .filter { accountFilter.matches(account: $0) }
            .filter { trimmed.isEmpty || $0.name.lowercased().contains(trimmed) }
            .map { account in
                let cloudBackedUp = cloudBackupManager.backedUp(uniqueId: account.type.uniqueId())
                return Item(account: account, cloudBackedUp: cloudBackedUp, isActive: account == activeAccount)
            }

        if accountFilter == .all {
            let regular = mapped.filter { !$0.account.watchAccount }
                .sorted { $0.account.name.lowercased() < $1.account.name.lowercased() }
            let watch = mapped.filter(\.account.watchAccount)
                .sorted { $0.account.name.lowercased() < $1.account.name.lowercased() }
            items = regular + watch
        } else {
            items = mapped.sorted { $0.account.name.lowercased() < $1.account.name.lowercased() }
        }
    }
}

extension ManageAccountsViewModel {
    var hasAccounts: Bool {
        !accountManager.accounts.isEmpty
    }

    var hasFilters: Bool {
        availableFilters.count > 2 // has .all + only one type.
    }

    var accountFilterIndex: Int {
        availableFilters.firstIndex(of: accountFilter) ?? 0
    }

    func setAccountFilter(index: Int) {
        guard availableFilters.indices.contains(index) else {
            accountFilter = .all
            return
        }
        accountFilter = availableFilters[index]
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

    enum AccountFilter: String, Identifiable, Hashable {
        case all
        case mnemonic
        case privateKey
        case watch

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "filter.all".localized
            case .mnemonic: return "filter.mnemonic".localized
            case .privateKey: return "filter.private_key".localized
            case .watch: return "filter.watch".localized
            }
        }

        func matches(account: Account) -> Bool {
            switch self {
            case .all:
                return true
            case .mnemonic:
                if case .mnemonic = account.type { return true }
                return false
            case .privateKey:
                switch account.type {
                case .evmPrivateKey, .trcPrivateKey, .stellarSecretKey:
                    return true
                case let .hdExtendedKey(key):
                    if case .private = key { return true }
                    return false
                default:
                    return false
                }
            case .watch:
                return account.watchAccount
            }
        }
    }
}
