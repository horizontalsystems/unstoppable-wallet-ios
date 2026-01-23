import Combine
import Foundation
import HsToolKit
import ZcashLightClientKit

/// Scans historical addresses (before lastUsed) to detect if any became used
/// Dynamically updates the scan list when lastUsed changes
actor SingleUseHistoricalScanner {
    private static let checkDelay: TimeInterval = 2.0

    private let synchronizer: Synchronizer
    private let storage: ZcashAdapterStorage
    private let walletId: String
    private let logger: HsToolKit.Logger?

    private var isRunning = false
    private var currentTask: Task<Void, Never>?

    /// Current lastUsed address that scanner is working with
    private var currentLastUsed: SingleUseAddress?

    /// Addresses currently in the scanning queue
    private var addressQueue: [SingleUseAddress] = []

    /// Set of addresses already checked in current session (to avoid duplicates)
    private var checkedAddresses: Set<String> = []

    private let eventSubject = PassthroughSubject<ScannerEvent, Never>()
    var events: AnyPublisher<ScannerEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(
        synchronizer: Synchronizer,
        storage: ZcashAdapterStorage,
        walletId: String,
        logger: HsToolKit.Logger? = nil
    ) {
        self.synchronizer = synchronizer
        self.storage = storage
        self.walletId = walletId
        self.logger = logger

        logger?.log(level: .debug, message: "HistoricalScanner: Initialized")
    }

    /// Start or update scanning with new lastUsed address
    /// - Parameter lastUsed: The lastUsed address to scan before. If nil, fetches from storage
    func update(lastUsed: SingleUseAddress?) async {
        logger?.log(level: .debug, message: "HistoricalScanner: update() called with lastUsed: \(lastUsed?.address ?? "nil")")

        let targetLastUsed = lastUsed ?? (try? storage.lastUsedAddress(walletId: walletId))

        // Check if lastUsed changed
        if let targetLastUsed {
            if currentLastUsed?.address != targetLastUsed.address {
                logger?.log(level: .debug, message: "HistoricalScanner: LastUsed changed: \(currentLastUsed?.address ?? "nil") → \(targetLastUsed.address)")

                currentLastUsed = targetLastUsed

                // Update queue with new addresses
                await updateQueue()

                // Start if not running
                if !isRunning {
                    await start()
                }
            } else {
                logger?.log(level: .debug, message: "HistoricalScanner: LastUsed unchanged, no action needed")
            }
        } else {
            logger?.log(level: .debug, message: "HistoricalScanner: No lastUsed address, nothing to scan")
        }
    }

    /// Stop scanning
    func stop() async {
        logger?.log(level: .debug, message: "HistoricalScanner: stop() called")

        guard isRunning else {
            logger?.log(level: .debug, message: "HistoricalScanner: Not running, nothing to stop")
            return
        }

        currentTask?.cancel()
        currentTask = nil
        isRunning = false
        addressQueue.removeAll()
        checkedAddresses.removeAll()
        currentLastUsed = nil

        logger?.log(level: .debug, message: "HistoricalScanner: Stopped and cleared state")
    }

    // MARK: - Private Methods

    private func start() async {
        logger?.log(level: .debug, message: "HistoricalScanner: start() - Starting scan task")

        guard !isRunning else {
            logger?.log(level: .debug, message: "HistoricalScanner: Already running")
            return
        }

        isRunning = true

        currentTask = Task {
            await scan()
        }
    }

    /// Update the queue with new addresses from storage
    private func updateQueue() async {
        guard let lastUsed = currentLastUsed else {
            logger?.log(level: .debug, message: "HistoricalScanner: updateQueue() - No lastUsed, clearing queue")
            addressQueue.removeAll()
            return
        }

        logger?.log(level: .debug, message: "HistoricalScanner: updateQueue() - Fetching addresses before \(lastUsed.address)")

        do {
            // Get all unused addresses before lastUsed
            let addresses = try storage.addresses(
                walletId: walletId,
                before: lastUsed.address,
                unused: true
            )

            logger?.log(level: .debug, message: "HistoricalScanner: updateQueue() - Found \(addresses.count) unused addresses in storage")

            // Filter out already checked addresses
            let newAddresses = addresses.filter { !checkedAddresses.contains($0.address) }

            logger?.log(level: .debug, message: "HistoricalScanner: updateQueue() - \(newAddresses.count) new addresses (not yet checked)")

            // Add new addresses to the END of queue (preserve order)
            addressQueue = newAddresses

            logger?.log(level: .debug, message: "HistoricalScanner: updateQueue() - Queue now contains \(addressQueue.count) addresses")
        } catch {
            logger?.log(level: .error, message: "HistoricalScanner: updateQueue() - Failed to fetch addresses: \(error)")
        }
    }

    private func scan() async {
        logger?.log(level: .debug, message: "HistoricalScanner: scan() - Starting scanning loop")

        while !Task.isCancelled, isRunning {
            // Check if queue is empty
            if addressQueue.isEmpty {
                logger?.log(level: .debug, message: "HistoricalScanner: scan() - Queue empty, checking for new addresses...")
                await updateQueue()

                if addressQueue.isEmpty {
                    logger?.log(level: .debug, message: "HistoricalScanner: scan() - No more addresses to check, stopping")
                    break
                }
            }

            // Get next address from queue
            let address = addressQueue.removeFirst()

            logger?.log(level: .debug, message: "HistoricalScanner: scan() - Checking address [queue: \(addressQueue.count) remaining] gapIndex=\(address.gapIndex): \(address.address)")

            // Check address
            do {
                let wasUsed = try await checkAddress(address)

                // Mark as checked
                checkedAddresses.insert(address.address)

                if wasUsed {
                    logger?.log(level: .debug, message: "HistoricalScanner: scan() - ✅ Found USED address: \(address.address)")

                    // Publish event
                    eventSubject.send(.addressMarkedAsUsed(address))
                }

            } catch {
                logger?.log(level: .error, message: "HistoricalScanner: scan() - Error checking address: \(error)")
                // Continue with next address
            }

            // Delay before next check
            if !addressQueue.isEmpty {
                logger?.log(level: .debug, message: "HistoricalScanner: scan() - Waiting \(Self.checkDelay)s before next check...")
                try? await Task.sleep(nanoseconds: UInt64(Self.checkDelay * 1_000_000_000))
            }
        }

        isRunning = false
        logger?.log(level: .debug, message: "HistoricalScanner: scan() - Scan loop finished")
    }

    private func checkAddress(_ address: SingleUseAddress) async throws -> Bool {
        logger?.log(level: .debug, message: "HistoricalScanner: checkAddress() - Checking \(address.address)")

        let result = try await synchronizer.updateTransparentAddressTransactions(address: address.address)

        logger?.log(level: .debug, message: "HistoricalScanner: checkAddress() - Result: \(result)")

        switch result {
        case let .found(foundAddress):
            logger?.log(level: .debug, message: "HistoricalScanner: checkAddress() - ✅✅✅ FOUND transactions on: \(foundAddress)")

            var updatedAddress = address
            updatedAddress.markAsUsed()
            try storage.update(address: updatedAddress)

            logger?.log(level: .debug, message: "HistoricalScanner: checkAddress() - Address marked as USED in storage")

            return true

        case .notFound:
            logger?.log(level: .debug, message: "HistoricalScanner: checkAddress() - No transactions found")
            return false
        case .torRequired:
            logger?.log(level: .debug, message: "HistoricalScanner: Tor must be Enabled!")
            return false
        }
    }
}

extension SingleUseHistoricalScanner {
    enum ScannerEvent {
        case addressMarkedAsUsed(SingleUseAddress)
    }
}
