import Foundation
import Combine
import HsToolKit
import HsExtensions

class CloudAccountBackupManager {
    static private let batchingInterval: TimeInterval = 1
    static private let fileExtension = ".json"

    private let ubiquityContainerIdentifier: String?
    private let fileStorage: FileStorage
    private let logger: Logger?

    private var metadataMonitor: MetadataMonitorNew?
    private var publishers = [AnyCancellable]()

    var iCloudUrl: URL? {
        FileManager
                .default
                .url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier)?
                .appendingPathComponent("Documents")
    }

    @PostPublished private(set) var items = [String: WalletBackup]()
    @PostPublished private(set) var state = State.loading

    init(ubiquityContainerIdentifier: String?, logger: Logger?) {
        self.ubiquityContainerIdentifier = ubiquityContainerIdentifier

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

        let metadataMonitor = MetadataMonitorNew(url: url, batchingInterval: Self.batchingInterval, logger: logger)
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

        Task { [weak self, fileStorage, logger] in
            do {
                self?.forceDownloadContainerFiles(url: url)
                let items = try await Self.downloadItems(url: url, fileStorage: fileStorage, logger: logger)

                self?.state = .success
                logger?.log(level: .debug, message: "CloudAccountManager.state = \(state)")
                self?.items = items
            } catch {
                self?.state = .error(error)
                logger?.log(level: .debug, message: "CloudAccountManager.state = \(state)")
            }
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

    private static func downloadItems(url: URL, fileStorage: FileStorage, logger: Logger? = nil) async throws -> [String: WalletBackup] {
        let files = try fileStorage.fileList(url: url).filter { s in s.contains(Self.fileExtension) }
        var items = [String: WalletBackup]()

        for file in files {
            do {
                let data = try await fileStorage.read(directoryUrl: url, filename: file)
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

    func save(accountType: AccountType, isManualBackedUp: Bool, passphrase: String, name: String) async throws {
        guard let iCloudUrl else {
            throw BackupError.urlNotAvailable
        }

        do {
            let name = name + Self.fileExtension
            let encoded = try WalletBackupConverter.encode(accountType: accountType, isManualBackedUp: isManualBackedUp, passphrase: passphrase)

            try await fileStorage.write(directoryUrl: iCloudUrl, filename: name, data: encoded)
            logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, save \(name)")
        } catch {
            logger?.log(level: .debug, message: "CloudAccountManager.downloadItems, can't save \(name). Because: \(error)")
            throw error
        }

    }

    func delete(uniqueId: Data) async throws {
        guard let iCloudUrl else {
            throw BackupError.urlNotAvailable
        }

        guard let item = items.first(where: { name, backup in backup.id == uniqueId.hs.hex }) else {
            throw BackupError.itemNotFound
        }

        let fileUrl = iCloudUrl.appendingPathComponent(item.key)
        do {
            try await fileStorage.deleteFile(url: fileUrl)

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
