import Combine
import Foundation
import HsToolKit
import ZcashLightClientKit

/// Monitors active addresses (after lastUsed) to detect new incoming transactions
/// Stops and signals when finds a new used address
actor SingleUseActiveMonitor {
    private static let checkDelay: TimeInterval = 2.0

    private let synchronizer: Synchronizer
    private let storage: ZcashAdapterStorage
    private let walletId: String
    private let logger: HsToolKit.Logger?

    private var isRunning = false
    private var currentTask: Task<Void, Never>?

    /// Current lastUsed address that monitor is working with
    private var currentLastUsed: SingleUseAddress?

    /// Addresses currently in the monitoring queue
    private var addressQueue: [SingleUseAddress] = []

    /// Set of addresses already checked in current session (to avoid duplicates)
    private var checkedAddresses: Set<String> = []

    private let eventSubject = PassthroughSubject<MonitorEvent, Never>()
    var events: AnyPublisher<MonitorEvent, Never> {
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

        logger?.log(level: .debug, message: "ActiveMonitor: Initialized")
    }

    /// Start monitoring. Fetches current lastUsed from storage and begins monitoring.
    func start() async {
        logger?.log(level: .debug, message: "ActiveMonitor: start() called")

        guard !isRunning else {
            logger?.log(level: .debug, message: "ActiveMonitor: Already running, skipping start")
            return
        }

        // Fetch current lastUsed from storage
        currentLastUsed = try? storage.lastUsedAddress(walletId: walletId)
        logger?.log(level: .debug, message: "ActiveMonitor: Starting with lastUsed: \(currentLastUsed?.address ?? "nil")")

        checkedAddresses.removeAll()
        await updateQueue()

        guard !addressQueue.isEmpty else {
            logger?.log(level: .debug, message: "ActiveMonitor: No addresses to monitor, not starting")
            return
        }

        isRunning = true
        currentTask = Task {
            await monitor()
        }

        logger?.log(level: .debug, message: "ActiveMonitor: Started with \(addressQueue.count) addresses in queue")
    }

    /// Update monitoring with new lastUsed address. Restarts if lastUsed changed.
    /// - Parameter lastUsed: The new lastUsed address. If nil, fetches from storage.
    func update(lastUsed: SingleUseAddress?) async {
        logger?.log(level: .debug, message: "ActiveMonitor: update() called with lastUsed: \(lastUsed?.address ?? "nil")")

        guard isRunning else {
            logger?.log(level: .debug, message: "ActiveMonitor: Not running, calling start() instead")
            await start()
            return
        }

        let targetLastUsed = lastUsed ?? (try? storage.lastUsedAddress(walletId: walletId))

        // Check if lastUsed actually changed
        let currentAddress = currentLastUsed?.address
        let targetAddress = targetLastUsed?.address

        if currentAddress != targetAddress {
            logger?.log(level: .debug, message: "ActiveMonitor: LastUsed changed: \(currentAddress ?? "nil") → \(targetAddress ?? "nil"), restarting")
            await stop()
            await start()
        } else {
            logger?.log(level: .debug, message: "ActiveMonitor: LastUsed unchanged, continuing")
        }
    }

    func stop() async {
        logger?.log(level: .debug, message: "ActiveMonitor: stop() called")

        guard isRunning else {
            logger?.log(level: .debug, message: "ActiveMonitor: Not running, nothing to stop")
            return
        }

        currentTask?.cancel()
        currentTask = nil
        isRunning = false
        addressQueue.removeAll()
        checkedAddresses.removeAll()
        currentLastUsed = nil

        logger?.log(level: .debug, message: "ActiveMonitor: Stopped and cleared state")
    }

    private func updateQueue() async {
        logger?.log(level: .debug, message: "ActiveMonitor: updateQueue() - Fetching addresses")

        do {
            let addresses: [SingleUseAddress]

            if let lastUsed = currentLastUsed {
                // Get all unused addresses AFTER lastUsed
                logger?.log(level: .debug, message: "ActiveMonitor: updateQueue() - Fetching addresses after \(lastUsed.address)")
                addresses = try storage.addresses(
                    walletId: walletId,
                    after: lastUsed.address,
                    unused: true
                )
            } else {
                // No lastUsed = first time - get ALL unused addresses
                logger?.log(level: .debug, message: "ActiveMonitor: updateQueue() - No lastUsed, fetching ALL unused addresses")
                addresses = try storage.addresses(
                    walletId: walletId,
                    after: nil,
                    unused: true
                )
            }

            logger?.log(level: .debug, message: "ActiveMonitor: updateQueue() - Found \(addresses.count) unused addresses in storage")

            // Filter out already checked addresses
            let newAddresses = addresses.filter { !checkedAddresses.contains($0.address) }

            logger?.log(level: .debug, message: "ActiveMonitor: updateQueue() - \(newAddresses.count) new addresses (not yet checked)")

            // Replace queue with fresh list
            addressQueue = newAddresses

            logger?.log(level: .debug, message: "ActiveMonitor: updateQueue() - Queue now contains \(addressQueue.count) addresses")
        } catch {
            logger?.log(level: .error, message: "ActiveMonitor: updateQueue() - Failed to fetch addresses: \(error)")
        }
    }

    private func monitor() async {
        logger?.log(level: .debug, message: "ActiveMonitor: monitor() - Starting monitoring loop")

        while !Task.isCancelled, isRunning {
            // Check if queue is empty
            if addressQueue.isEmpty {
                logger?.log(level: .debug, message: "ActiveMonitor: monitor() - Queue empty, checking for new addresses...")
                await updateQueue()

                if addressQueue.isEmpty {
                    logger?.log(level: .debug, message: "ActiveMonitor: monitor() - No more addresses to check, stopping")
                    break
                }
            }

            // Get next address from queue
            let address = addressQueue.removeFirst()

            logger?.log(level: .debug, message: "ActiveMonitor: monitor() - Checking address [queue: \(addressQueue.count) remaining] gapIndex=\(address.gapIndex): \(address.address)")

            // Check address
            do {
                let wasUsed = try await checkAddress(address)

                // Mark as checked
                checkedAddresses.insert(address.address)

                if wasUsed {
                    logger?.log(level: .debug, message: "ActiveMonitor: monitor() - Found NEW USED address: \(address.address)")

                    // Publish event about new used address
                    eventSubject.send(.newUsedAddressFound(address))

                    // Stop monitoring - manager will restart with new lastUsed
                    await stop()

                    logger?.log(level: .debug, message: "ActiveMonitor: monitor() - Stopped after finding new used address")
                    break
                }

            } catch {
                logger?.log(level: .error, message: "ActiveMonitor: monitor() - Error checking address: \(error)")
                // Continue with next address
            }

            // Delay before next check
            if !addressQueue.isEmpty {
                logger?.log(level: .debug, message: "ActiveMonitor: monitor() - Waiting \(Self.checkDelay)s before next check...")
                try? await Task.sleep(nanoseconds: UInt64(Self.checkDelay * 1_000_000_000))
            }
        }

        isRunning = false
        logger?.log(level: .debug, message: "ActiveMonitor: monitor() - Monitor loop finished")
    }

    private func checkAddress(_ address: SingleUseAddress) async throws -> Bool {
        logger?.log(level: .debug, message: "ActiveMonitor: checkAddress() - Checking \(address.address)")

        let result = try await synchronizer.updateTransparentAddressTransactions(address: address.address)

        logger?.log(level: .debug, message: "ActiveMonitor: checkAddress() - Result: \(result)")

        switch result {
        case let .found(foundAddress):
            logger?.log(level: .debug, message: "ActiveMonitor: checkAddress() - FOUND transactions on: \(foundAddress)")

            var updatedAddress = address
            updatedAddress.markAsUsed()
            try storage.update(address: updatedAddress)

            logger?.log(level: .debug, message: "ActiveMonitor: checkAddress() - Address marked as USED in storage")

            return true

        case .notFound:
            logger?.log(level: .debug, message: "ActiveMonitor: checkAddress() - No transactions found")
            return false

        case .torRequired:
            logger?.log(level: .debug, message: "ActiveMonitor: Tor must be Enabled!")
            return false
        }
    }
}

extension SingleUseActiveMonitor {
    enum MonitorEvent {
        case newUsedAddressFound(SingleUseAddress)
    }
}
