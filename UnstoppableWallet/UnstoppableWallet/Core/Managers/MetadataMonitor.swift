import Foundation
import RxSwift
import RxRelay

class MetadataMonitor {
    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.metadata_monitor", qos: .userInitiated)

    private let url: URL
    private let filename: String
    private let batchingInterval: TimeInterval

    private let itemUpdatedRelay = BehaviorRelay<Bool>(value: false)
    private let parsingErrorRelay = BehaviorRelay<Error?>(value: nil)

    private var metadataQuery: NSMetadataQuery?

    init(url: URL, filename: String, batchingInterval: TimeInterval) {
        self.url = url
        self.filename = filename
        self.batchingInterval = batchingInterval

        start()
    }

    deinit {
        if metadataQuery != nil {
            stop()
        }
    }

    private func start() {
        let predicate: NSPredicate = NSPredicate(
                format: "%K = FALSE AND %K BEGINSWITH %@ AND %K CONTAINS %@",
                NSMetadataUbiquitousItemIsDownloadingKey,
                NSMetadataItemPathKey,
                url.path,
                NSMetadataItemFSNameKey,
                filename
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

        for item in results {
            do {
                try resolveConflicts(for: item)
                guard let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL else { continue }
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
            } catch {
                parsingErrorRelay.accept(error)
            }
        }

        // Get the file URLs, to wait for them below.
        let urls = results.compactMap { item in
            item.value(forAttribute: NSMetadataItemURLKey) as? URL
        }

        self.metadataQuery?.enableUpdates()

        // Query existence of each file. This uses the file coordinator, and will
        // wait until they are available
        for url in urls {
            _ = try? FileManager.default.fileExists(coordinatingAccessAt: url)
        }

        // Inform observer
        if !urls.isEmpty {
            itemUpdatedRelay.accept(true)
            parsingErrorRelay.accept(nil)
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

    var itemUpdatedObservable: Observable<Bool> {
        itemUpdatedRelay.asObservable()
    }

    var parsingErrorObservable: Observable<Error?> {
        parsingErrorRelay.asObservable()
    }

}

extension MetadataMonitor {

    enum ResolverError: Error {
        case invalidMetadata
        case coordinationError(NSError)
    }

}
