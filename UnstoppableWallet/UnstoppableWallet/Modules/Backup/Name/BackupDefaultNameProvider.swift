protocol IBackupNameProvider {
    func defaultName() -> String
}

class WalletBackupNameProvider: IBackupNameProvider {
    private let accountManager = Core.shared.accountManager
    private let cloudBackupManager = Core.shared.cloudBackupManager

    private let accountId: String
    private let destination: BackupModule.Destination

    init(accountId: String, destination: BackupModule.Destination) {
        self.accountId = accountId
        self.destination = destination
    }

    func defaultName() -> String {
        let accountName = accountManager.account(id: accountId)?.name ?? "Wallet Backup"

        if destination == .cloud {
            return RestoreFileHelper.resolve(name: accountName, elements: cloudBackupManager.existFilenames)
        } else {
            return accountName
        }
    }
}

class AppBackupNameProvider: IBackupNameProvider {
    private let cloudBackupManager = Core.shared.cloudBackupManager

    private let destination: BackupModule.Destination

    init(destination: BackupModule.Destination) {
        self.destination = destination
    }

    func defaultName() -> String {
        let prefix = "App Backup"

        if destination == .cloud {
            return RestoreFileHelper.resolve(name: prefix, elements: cloudBackupManager.existFilenames)
        } else {
            return prefix
        }
    }
}

enum BackupNameProviderFactory {
    static func create(type: BackupModule.BackupType, destination: BackupModule.Destination) -> IBackupNameProvider {
        switch type {
        case let .wallet(accountId):
            return WalletBackupNameProvider(accountId: accountId, destination: destination)
        case .app:
            return AppBackupNameProvider(destination: destination)
        }
    }
}
