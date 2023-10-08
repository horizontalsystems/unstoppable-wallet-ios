import Combine
import Foundation
import HsExtensions
import HsToolKit

class CloudBackupManager {
    private static let batchingInterval: TimeInterval = 1
    private static let fileExtension = ".json"

    private let ubiquityContainerIdentifier: String?
    private let fileStorage: FileStorage
    private let appBackupProvider: AppBackupProvider
    private let logger: Logger?

    private var metadataMonitor: MetadataMonitor?
    private var publishers = [AnyCancellable]()

    var iCloudUrl: URL? {
        FileManager
            .default
            .url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier)?
            .appendingPathComponent("Documents")
    }

    @PostPublished private(set) var oneWalletItems = [String: WalletBackup]()
    @PostPublished private(set) var fullBackupItems = [String: FullBackup]()
    @PostPublished private(set) var state = State.loading

    init(ubiquityContainerIdentifier: String?, appBackupProvider: AppBackupProvider, logger: Logger?) {
        self.ubiquityContainerIdentifier = ubiquityContainerIdentifier
        self.appBackupProvider = appBackupProvider

        fileStorage = FileStorage(logger: logger)
        self.logger = logger

        initializeMetadataMonitor()

        reload()
    }

    private func initializeMetadataMonitor() {
        // create monitor and handle its events
        guard let url = iCloudUrl else {
            logger?.log(level: .debug, message: "CloudAccountManager.initializeMetadataMonitor, url not available.")
            state = .error(BackupError.urlNotAvailable)
            logger?.log(level: .debug, message: "CloudAccountManager.state = \(state)")
            return
        }

        let metadataMonitor = MetadataMonitor(url: url, batchingInterval: Self.batchingInterval, logger: logger)
        self.metadataMonitor = metadataMonitor
        logger?.debug("=C-MANAGER> Turn ON monitor")

        metadataMonitor.needUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.reload()
            }.store(in: &publishers)
    }

    private func reload() {
        state = .loading
        logger?.log(level: .debug, message: "CloudAccountManager.state = \(state)")

        guard let url = iCloudUrl else {
            logger?.log(level: .debug, message: "CloudAccountManager.forceDownloadContainerFiles, url not available.")
            state = .error(BackupError.urlNotAvailable)
            logger?.log(level: .debug, message: "CloudAccountManager.state = \(state)")
            return
        }

        do {
            forceDownloadContainerFiles(url: url)

            var oneWalletItems: [String: WalletBackup] = try Self.downloadItems(url: url, fileStorage: fileStorage, logger: logger)
            let oneWalletItemsV2: [String: RestoreCloudModule.RestoredBackup] = try Self.downloadItems(url: url, fileStorage: fileStorage, logger: logger)
            let mapped = oneWalletItemsV2.reduce(into: [:]) { $0[$1.value.name] = $1.value.walletBackup }

            oneWalletItems.merge(mapped) { _, backup2 in backup2 }
            let fullBackupItems: [String: FullBackup] = try Self.downloadItems(url: url, fileStorage: fileStorage, logger: logger)

            state = .success
            logger?.log(level: .debug, message: "CloudAccountManager.state = \(state)")

            self.oneWalletItems = oneWalletItems
            self.fullBackupItems = fullBackupItems
        } catch {
            state = .error(error)
            logger?.log(level: .debug, message: "CloudAccountManager.state = \(state)")
        }
    }

    private func forceDownloadContainerFiles(url: URL) {
        // try to download new files from cloud to local cloud storage
        // ignore any errors
        do {
            let files = try fileStorage.fileList(url: url)
            files.forEach { file in
                do {
                    try fileStorage.prepareUbiquitousItem(url: url, filename: file)
                } catch {
                    logger?.log(level: .debug, message: "CloudAccountManager.forceDownloadContainerFiles, can't prepareUbiquitousItem \(existFilenames)")
                }
            }
        } catch {
            logger?.log(level: .debug, message: "CloudAccountManager.forceDownloadContainerFiles, error: \(error)")
        }
    }

    private static func downloadItems<T: Decodable>(url: URL, fileStorage: FileStorage, logger: Logger? = nil) throws -> [String: T] {
        let files = try fileStorage.fileList(url: url).filter { s in s.contains(Self.fileExtension) }
        var items = [String: T]()

        for file in files {
            do {
                let data = try fileStorage.read(directoryUrl: url, filename: file)
                let backup = try JSONDecoder().decode(T.self, from: data)
                items[file] = backup
            } catch {
                logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, can't read \(file). Because: \(error)")
            }
        }

        logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, read \(items.count) files")
        return items
    }

    private func save(encoded: Data, name: String) throws {
        guard let iCloudUrl else {
            throw BackupError.urlNotAvailable
        }

        do {
            let name = name + Self.fileExtension

            try fileStorage.write(directoryUrl: iCloudUrl, filename: name, data: encoded)
            logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, save \(name)")
        } catch {
            logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, can't save \(name). Because: \(error)")
            throw error
        }
    }
}

extension CloudBackupManager {
    func backedUp(uniqueId: Data) -> Bool {
        oneWalletItems.contains { _, backup in backup.id == uniqueId.hs.hex }
    }

    var existFilenames: [String] {
        oneWalletItems.map { ($0.key as NSString).deletingPathExtension } +
            fullBackupItems.map { ($0.key as NSString).deletingPathExtension }
    }
}

extension CloudBackupManager {
    var isAvailable: Bool {
        iCloudUrl != nil
    }

    func save(account: Account, passphrase: String, name: String) throws {
        let backup = try AppBackupProvider.encrypt(
            account: account,
            wallets: appBackupProvider.enabledWallets(account: account),
            passphrase: passphrase
        )

        do {
            let encoded = try JSONEncoder().encode(backup)
            try save(encoded: encoded, name: name)
        } catch {
            logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, can't save \(name). Because: \(error)")
            throw error
        }
    }

    private func data(accountIds: [String], passphrase: String) throws -> Data {
        let rawBackup = appBackupProvider.fullBackup(accountIds: accountIds)
        let backup = try appBackupProvider.encrypt(raw: rawBackup, passphrase: passphrase)
        return try JSONEncoder().encode(backup)
    }

    func file(accountIds: [String], passphrase: String, name: String) throws -> URL {
        let data = try data(accountIds: accountIds, passphrase: passphrase)

        // save book to temporary file
        guard let temporaryFileUrl = ContactBookManager.localUrl?.appendingPathComponent(name + ".json") else {
            throw FileStorage.StorageError.cantCreateFile
        }

        try data.write(to: temporaryFileUrl)
        return temporaryFileUrl
    }

    func save(accountIds: [String], passphrase: String, name: String) throws {
        do {
            let encoded = try data(accountIds: accountIds, passphrase: passphrase)
            try save(encoded: encoded, name: name)
        } catch {
            logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, can't save \(name). Because: \(error)")
            throw error
        }
    }

    func delete(uniqueId: Data) throws {
        let hex = uniqueId.hs.hex
        try delete(uniqueId: hex)
    }

    func delete(name: String) throws {
        guard let iCloudUrl else {
            throw BackupError.urlNotAvailable
        }

        let fileUrl = iCloudUrl.appendingPathComponent(name)
        do {
            try fileStorage.deleteFile(url: fileUrl)

            // system will automatically updates items but after 1-2 seconds. So we need force update
            oneWalletItems[name] = nil
            logger?.log(level: .debug, message: "CloudAccountManager.delete \(name) successful")
        } catch {
            logger?.log(level: .debug, message: "CloudAccountManager.delete \(name) unsuccessful because: \(error)")
            throw error
        }
    }

    func delete(uniqueId: String) throws {
        guard let item = oneWalletItems.first(where: { _, backup in backup.id == uniqueId }) else {
            throw BackupError.itemNotFound
        }

        try delete(name: item.key)
    }
}

extension CloudBackupManager {
    enum BackupError: Error {
        case urlNotAvailable
        case itemNotFound
    }

    enum State {
        case loading
        case success
        case error(Error)
    }
}
