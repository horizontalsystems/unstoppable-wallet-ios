import Foundation

protocol IBackupService {
    func save(type: BackupModule.BackupType, name: String, password: String) async throws -> BackupModule.BackupResult
}

enum BackupServiceFactory {
    static func create(destination: BackupModule.Destination) -> IBackupService {
        switch destination {
        case .cloud: return CloudBackupService()
        case .files: return FileBackupService()
        }
    }
}

class CloudBackupService: IBackupService {
    private let cloudBackupManager = Core.shared.cloudBackupManager
    private let accountManager = Core.shared.accountManager

    func save(type: BackupModule.BackupType, name: String, password: String) async throws -> BackupModule.BackupResult {
        switch type {
        case let .wallet(accountId):
            guard let account = accountManager.account(id: accountId) else {
                throw BackupModule.BackupError.accountNotFound
            }
            try cloudBackupManager.save(account: account, passphrase: password, name: name)

        case let .app(accountIds):
            try cloudBackupManager.save(accountIds: Array(accountIds), passphrase: password, name: name)
        }

        return .saved
    }
}

class FileBackupService: IBackupService {
    private let cloudBackupManager = Core.shared.cloudBackupManager
    private let accountManager = Core.shared.accountManager

    func save(type: BackupModule.BackupType, name: String, password: String) async throws -> BackupModule.BackupResult {
        let url: URL

        switch type {
        case let .wallet(accountId):
            guard let account = accountManager.account(id: accountId) else {
                throw BackupModule.BackupError.accountNotFound
            }
            url = try cloudBackupManager.file(account: account, passphrase: password, name: name)

        case let .app(accountIds):
            url = try cloudBackupManager.file(accountIds: Array(accountIds), passphrase: password, name: name)
        }

        return .share(url)
    }
}
