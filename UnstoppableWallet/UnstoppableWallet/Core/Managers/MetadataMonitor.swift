import Foundation
import Combine
import HsExtensions
import HsToolKit

class MetadataMonitor {
    private let queue = DispatchQueue(label: "\(AppConfig.label).metadata_monitor", qos: .userInitiated)

    private let url: URL
    private let filenames: [String]
    private let batchingInterval: TimeInterval
    private let logger: Logger?

    private let needUpdateSubject = PassthroughSubject<Void, Never>()
    @PostPublished private(set) var parsingError: Error? = nil

    private var metadataQuery: NSMetadataQuery?
    private var fileChangedTime = [URL: Date]()

    init(url: URL, filenames: [String] = [], batchingInterval: TimeInterval, logger: Logger? = nil) {
        self.url = url
        self.filenames = filenames
        self.batchingInterval = batchingInterval
        self.logger = logger

        start()
    }

    deinit {
        if metadataQuery != nil {
            logger?.debug("Stop Metadata Monitor")
            stop()
        }
    }

    private func start() {
        let predicate: NSPredicate = NSPredicate(
                format: "%K = FALSE AND %K BEGINSWITH %@",
                NSMetadataUbiquitousItemIsDownloadingKey,
                NSMetadataItemPathKey,
                url.path
        )
        let metadataQuery = NSMetadataQuery()
        self.metadataQuery = metadataQuery

        metadataQuery.notificationBatchingInterval = batchingInterval
        metadataQuery.searchScopes = [
            NSMetadataQueryUbiquitousDataScope,
            NSMetadataQueryUbiquitousDocumentsScope,
        ]
        metadataQuery.predicate = predicate

        NotificationCenter.default.addObserver(self, selector: #selector(handle(_:)), name: .NSMetadataQueryDidFinishGathering, object: metadataQuery)
        NotificationCenter.default.addObserver(self, selector: #selector(handle(_:)), name: .NSMetadataQueryDidUpdate, object: metadataQuery)

        logger?.debug("Check url : \(url.path)")
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path) {
            logger?.debug(contents)
        }

        // Try to copy icloud file to local icloud, if it's exist
        do {
            for filename in filenames {
                try FileManager.default.startDownloadingUbiquitousItem(at: url.appendingPathComponent(filename))
            }
        } catch {
            logger?.debug("Can't download because : \(error)")
        }

        DispatchQueue.main.async {
            metadataQuery.start()
        }
    }

    private func stop() {
        metadataQuery?.disableUpdates()
        metadataQuery?.stop()

        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: metadataQuery)
        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: metadataQuery)

        metadataQuery = nil
    }

    func enableUpdates() {
        metadataQuery?.enableUpdates()
    }

    func disableUpdates() {
        metadataQuery?.disableUpdates()
    }

    @objc private func handle(_ notification: Notification) {
        logger?.debug("=> META MONITOR: has notification!")
        queue.async { [weak self] in
            self?.initiateDownloads()
        }
    }

    private func initiateDownloads() {
        metadataQuery?.disableUpdates()

        // check if file items come in array
        guard let results = metadataQuery?.results as? [NSMetadataItem] else {
            return
        }

        // remove all not-needed to monitoring items
        let filtered = filenames.isEmpty ? results : results.compactMap { item -> NSMetadataItem? in
            guard let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL else {
                return nil
            }
            for filename in filenames {
                if url.absoluteString.lowercased().contains(filename.lowercased()) {
                    return item
                }
            }
            return nil
        }

        logger?.debug("=> META MONITOR: INITIAL DOWNLOAD for \(filtered.count)")
        for item in filtered {
            do {
                try resolveConflicts(for: item)
                guard let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL else { continue }

                try FileManager.default.startDownloadingUbiquitousItem(at: url)
            } catch {
                parsingError = error
            }
        }

        // Get the file URLs, to wait for them below.
        let urls = filtered.compactMap { item -> URL? in
            // check if file really changed in time because query returns 3 times same file
            logger?.debug("=> MONITOR : url : \((item.value(forAttribute: NSMetadataItemURLKey) as? URL)?.path ?? "N/A")")
            if let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL {
                logger?.debug("=> MONITOR : changeTime : \(String(describing: item.value(forAttribute: NSMetadataItemFSContentChangeDateKey) as? Date))")
                let changeTime = item.value(forAttribute: NSMetadataItemFSContentChangeDateKey) as? Date
                logger?.debug("=> MONITOR : lastChangeTime : \(String(describing: fileChangedTime[url]))")
                if let changeTime,
                   let lastChangeTime = fileChangedTime[url],
                   changeTime == lastChangeTime {

                    logger?.debug("IGNORE FILE")
                    return nil
                }

                logger?.debug("UPDATE FILE TIME and handle URl")
                fileChangedTime[url] = changeTime
                return url
            }

            return nil
        }

        metadataQuery?.enableUpdates()

        // Query existence of each file. This uses the file coordinator, and will
        // wait until they are available
        for url in urls {
            _ = try? FileManager.default.fileExists(coordinatingAccessAt: url)
        }

        // Inform observer
        if !urls.isEmpty {
            needUpdateSubject.send(())
            parsingError = nil
        }
    }

    private func resolveConflicts(for item: NSMetadataItem) throws {
        guard
                let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL,
                let inConflict = item.value(forAttribute: NSMetadataUbiquitousItemHasUnresolvedConflictsKey) as? Bool else {
            throw ResolverError.invalidMetadata
        }
        guard inConflict else {
            return
        }

        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinatorError: NSError?
        var versionError: Swift.Error?
        coordinator.coordinate(writingItemAt: url, options: .forDeleting, error: &coordinatorError) { newURL in
            do {
                try NSFileVersion.removeOtherVersionsOfItem(at: newURL)
            } catch {
                versionError = error
            }
        }

        if let versionError {
            throw versionError
        }
        if let coordinatorError {
            throw ResolverError.coordinationError(coordinatorError)
        }

        let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: url)
        conflictVersions?.forEach { $0.isResolved = true }
    }

}

extension MetadataMonitor {

    var needUpdatePublisher: AnyPublisher<Void, Never> {
        needUpdateSubject.eraseToAnyPublisher()
    }

}

extension MetadataMonitor {

    enum ResolverError: Error {
        case invalidMetadata
        case coordinationError(NSError)
    }

}
