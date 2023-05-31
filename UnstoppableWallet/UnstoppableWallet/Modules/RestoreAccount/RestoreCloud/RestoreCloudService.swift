import Foundation
import Combine

class RestoreCloudService {
    private let cloudAccountBackupManager: CloudAccountBackupManager
    private let accountManager: AccountManager

    private var cancellables = Set<AnyCancellable>()

    @Published var items = [Item]()

    init(cloudAccountBackupManager: CloudAccountBackupManager, accountManager: AccountManager) {
        self.cloudAccountBackupManager = cloudAccountBackupManager
        self.accountManager = accountManager

        cloudAccountBackupManager.$items
                .sink { [weak self] in
                        self?.sync(backups: $0)
                }
                .store(in: &cancellables)

        sync(backups: cloudAccountBackupManager.items)
    }

    private func sync(backups: [String: WalletBackup]) {
        let accountUniqueIds = accountManager.accounts.map { $0.type.uniqueId().hs.hex }

        let items = backups.map { backup in
            Item(
                    name: withoutExtension(backup.key),
                    backup: backup.value,
                    imported: accountUniqueIds.contains(backup.value.id)
            )
        }

        self.items = items.sorted { (item1: Item, item2: Item) in
            if item1.backup.timestamp == nil && item2.backup.timestamp == nil  {
                return item1.name > item2.name
            }
            return (item1.backup.timestamp ?? 0) > (item2.backup.timestamp ?? 0)
        }
    }

    private func withoutExtension(_ name: String) -> String {
        (name as NSString).deletingPathExtension
    }

}

extension RestoreCloudService {
}

extension RestoreCloudService {

    struct Item {
        let name: String
        let backup: WalletBackup
        let imported: Bool
    }

}
