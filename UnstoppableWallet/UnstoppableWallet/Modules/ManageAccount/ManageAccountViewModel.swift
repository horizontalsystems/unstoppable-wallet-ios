import Combine

class ManageAccountViewModel: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let cloudBackupManager = Core.shared.cloudBackupManager
    private let passcodeManager = Core.shared.passcodeManager
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var account: Account
    @Published var name: String
    @Published var isCloudBackedUp = false

    init(account: Account) {
        self.account = account
        name = account.name

        accountManager.accountUpdatedPublisher
            .sink { [weak self] in self?.handleUpdated(account: $0) }
            .store(in: &cancellables)

        cloudBackupManager.$oneWalletItems
            .sink { [weak self] _ in self?.syncCloudBackedUp() }
            .store(in: &cancellables)

        syncCloudBackedUp()
    }

    private func syncCloudBackedUp() {
        isCloudBackedUp = cloudBackupManager.backedUp(uniqueId: account.type.uniqueId())
    }

    private func handleUpdated(account: Account) {
        if account.id == self.account.id {
            self.account = account
        }
    }
}

extension ManageAccountViewModel {
    var recoveryPhraseVisible: Bool {
        switch account.type {
        case .mnemonic: return true
        default: return false
        }
    }

    var privateKeysVisible: Bool {
        switch account.type {
        case .mnemonic, .evmPrivateKey, .stellarSecretKey: return true
        case let .hdExtendedKey(key):
            switch key {
            case .private: return true
            default: return false
            }
        default: return false
        }
    }

    var publicKeysVisible: Bool {
        switch account.type {
        case .mnemonic, .evmPrivateKey, .hdExtendedKey: return true
        default: return false
        }
    }

    func save() {
        account.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        accountManager.update(account: account)
    }

    func deleteCloudBackup() throws {
        try cloudBackupManager.delete(uniqueId: account.type.uniqueId())
    }

    func deleteAccount() {
        accountManager.delete(account: account)
    }
}
