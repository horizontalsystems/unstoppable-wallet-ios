import Combine
import Foundation

class CloudRestoreBackupService {
    private let cloudAccountBackupManager: CloudBackupManager
    private let accountManager: AccountManager

    private var cancellables = Set<AnyCancellable>()

    private let deleteItemCompletedSubject = PassthroughSubject<Bool, Never>()
    @Published var oneWalletItems = [WalletItem]()
    @Published var fullBackupItems = [AppItem]()

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
            WalletItem(
                name: withoutExtension(backup.key),
                backup: backup.value,
                imported: accountUniqueIds.contains(backup.value.id)
            )
        }

        oneWalletItems = items.sorted()
    }

    private func sync(fullBackupItems: [String: FullBackup]) {
        let items = fullBackupItems.map { backup in
            AppItem(name: withoutExtension(backup.key), backup: backup.value)
        }

        self.fullBackupItems = items.sorted()
    }

    private func withoutExtension(_ name: String) -> String {
        (name as NSString).deletingPathExtension
    }
}

extension CloudRestoreBackupService {
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

extension CloudRestoreBackupService {
    class Item: Comparable, Equatable {
        let name: String
        var id: String { fatalError() } // Override in subclasses
        var timestamp: TimeInterval? { nil } // Override in subclasses

        init(name: String) {
            self.name = name
        }

        static func == (lhs: Item, rhs: Item) -> Bool {
            lhs.id == rhs.id
        }

        static func < (lhs: Item, rhs: Item) -> Bool {
            if lhs.timestamp == nil, rhs.timestamp == nil {
                return lhs.name < rhs.name
            }
            return (lhs.timestamp ?? 0) < (rhs.timestamp ?? 0)
        }
    }

    class WalletItem: Item {
        let backup: WalletBackup
        let imported: Bool

        init(name: String, backup: WalletBackup, imported: Bool) {
            self.backup = backup
            self.imported = imported
            super.init(name: name)
        }

        override var id: String {
            backup.id
        }

        override var timestamp: TimeInterval? {
            backup.timestamp
        }
    }

    class AppItem: Item {
        let backup: FullBackup

        init(name: String, backup: FullBackup) {
            self.backup = backup
            super.init(name: name)
        }

        override var id: String {
            backup.id
        }

        override var timestamp: TimeInterval? {
            backup.timestamp
        }
    }
}
