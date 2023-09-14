import Combine
import Foundation
import HsExtensions
import HsToolKit

class CloudAccountBackupManager {
    private static let batchingInterval: TimeInterval = 1
    private static let fileExtension = ".json"

    private let ubiquityContainerIdentifier: String?
    private let fileStorage: FileStorage
    private let restoreSettingsManager: RestoreSettingsManager
    private let logger: Logger?

    private var metadataMonitor: MetadataMonitor?
    private var publishers = [AnyCancellable]()

    var iCloudUrl: URL? {
        FileManager
            .default
            .url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier)?
            .appendingPathComponent("Documents")
    }

    @PostPublished private(set) var items = [String: WalletBackup]()
    @PostPublished private(set) var state = State.loading

    init(ubiquityContainerIdentifier: String?, restoreSettingsManager: RestoreSettingsManager, logger: Logger?) {
        self.ubiquityContainerIdentifier = ubiquityContainerIdentifier
        self.restoreSettingsManager = restoreSettingsManager

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
            let items = try Self.downloadItems(url: url, fileStorage: fileStorage, logger: logger)

            state = .success
            logger?.log(level: .debug, message: "CloudAccountManager.state = \(state)")
            self.items = items
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

    private static func downloadItems(url: URL, fileStorage: FileStorage, logger: Logger? = nil) throws -> [String: WalletBackup] {
        let files = try fileStorage.fileList(url: url).filter { s in s.contains(Self.fileExtension) }
        var items = [String: WalletBackup]()

        for file in files {
            do {
                let data = try fileStorage.read(directoryUrl: url, filename: file)
                let backup = try JSONDecoder().decode(WalletBackup.self, from: data)
                items[file] = backup
            } catch {
                logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, can't read \(file). Because: \(error)")
            }
        }

        logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, read \(items.count) files")
        return items
    }
}

extension CloudAccountBackupManager {
    func backedUp(uniqueId: Data) -> Bool {
        items.contains { _, backup in backup.id == uniqueId.hs.hex }
    }

    var existFilenames: [String] {
        items.map { ($0.key as NSString).deletingPathExtension }
    }
}

extension CloudAccountBackupManager {
    var isAvailable: Bool {
        iCloudUrl != nil
    }

    func save(account: Account, wallets: [Wallet], isManualBackedUp: Bool, passphrase: String, name: String) throws {
        guard let iCloudUrl else {
            throw BackupError.urlNotAvailable
        }

        do {
            let name = name + Self.fileExtension
            let encoded = try WalletBackupConverter.encode(
                accountType: account.type,
                wallets: wallets.map {
                    let settings = restoreSettingsManager
                        .settings(accountId: account.id, blockchainType: $0.token.blockchainType)
                        .reduce(into: [:], { $0[$1.0.rawValue] = $1.1 })

                    return WalletBackup.EnabledWallet($0, settings: settings)
                },
                isManualBackedUp: isManualBackedUp,
                passphrase: passphrase
            )

            try fileStorage.write(directoryUrl: iCloudUrl, filename: name, data: encoded)
            logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, save \(name)")
        } catch {
            logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, can't save \(name). Because: \(error)")
            throw error
        }
    }

    func delete(uniqueId: Data) throws {
        let hex = uniqueId.hs.hex
        try delete(uniqueId: hex)
    }

    func delete(uniqueId: String) throws {
        guard let iCloudUrl else {
            throw BackupError.urlNotAvailable
        }

        guard let item = items.first(where: { _, backup in backup.id == uniqueId }) else {
            throw BackupError.itemNotFound
        }

        let fileUrl = iCloudUrl.appendingPathComponent(item.key)
        do {
            try fileStorage.deleteFile(url: fileUrl)

            // system will automatically updates items but after 1-2 seconds. So we need force update
            items[item.key] = nil

            logger?.log(level: .debug, message: "CloudAccountManager.delete \(item.key) successful")
        } catch {
            logger?.log(level: .debug, message: "CloudAccountManager.delete \(item.key) unsuccessful because: \(error)")
            throw error
        }
    }
}

extension CloudAccountBackupManager {
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
