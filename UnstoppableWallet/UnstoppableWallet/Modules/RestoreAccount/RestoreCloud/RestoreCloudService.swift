import Combine
import Foundation

class RestoreCloudService {
    private let cloudAccountBackupManager: CloudBackupManager
    private let accountManager: AccountManager

    private var cancellables = Set<AnyCancellable>()

    private let deleteItemCompletedSubject = PassthroughSubject<Bool, Never>()
    @Published var oneWalletItems = [Item]()
    @Published var fullBackupItems = [Item]()

    init(cloudAccountBackupManager: CloudBackupManager, accountManager: AccountManager) {
        self.cloudAccountBackupManager = cloudAccountBackupManager
        self.accountManager = accountManager

        cloudAccountBackupManager.$oneWalletItems
            .sink { [weak self] in
                self?.sync(backups: $0)
            }
            .store(in: &cancellables)

        cloudAccountBackupManager.$fullBackupItems
            .sink { [weak self] in
                self?.sync(fullBackupItems: $0)
            }
            .store(in: &cancellables)

        sync(backups: cloudAccountBackupManager.oneWalletItems)
        sync(fullBackupItems: cloudAccountBackupManager.fullBackupItems)
    }

    private func sync(backups: [String: WalletBackup]) {
        let accountUniqueIds = accountManager.accounts.map { $0.type.uniqueId().hs.hex }

        let items = backups.map { backup in
            Item(
                name: withoutExtension(backup.key),
                source: .wallet(backup.value),
                imported: accountUniqueIds.contains(backup.value.id)
            )
        }

        oneWalletItems = items.sorted { (item1: Item, item2: Item) in
            if item1.source.timestamp == nil, item2.source.timestamp == nil {
                return item1.name > item2.name
            }
            return (item1.source.timestamp ?? 0) > (item2.source.timestamp ?? 0)
        }
    }

    private func sync(fullBackupItems: [String: FullBackup]) {
        let items = fullBackupItems.map { backup in
            Item(
                name: withoutExtension(backup.key),
                source: .full(backup.value),
                imported: false
            )
        }

        self.fullBackupItems = items.sorted { (item1: Item, item2: Item) in
            if item1.source.timestamp == nil, item2.source.timestamp == nil {
                return item1.name > item2.name
            }
            return (item1.source.timestamp ?? 0) > (item2.source.timestamp ?? 0)
        }
    }

    private func withoutExtension(_ name: String) -> String {
        (name as NSString).deletingPathExtension
    }
}

extension RestoreCloudService {
    func remove(id: String) {
        do {
            try cloudAccountBackupManager.delete(uniqueId: id)
            deleteItemCompletedSubject.send(true)
        } catch {
            deleteItemCompletedSubject.send(false)
        }
    }

    var deleteItemCompletedPublisher: AnyPublisher<Bool, Never> {
        deleteItemCompletedSubject.eraseToAnyPublisher()
    }
}

extension RestoreCloudService {
    struct Item {
        let name: String
        let source: BackupModule.Source
        let imported: Bool
    }
}
