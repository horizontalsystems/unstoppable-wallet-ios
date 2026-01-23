import Combine
import Foundation
import HsToolKit
import ZcashLightClientKit

class SingleUseAddressManager {
    private let synchronizer: Synchronizer
    private let storage: ZcashAdapterStorage
    private let walletId: String
    private var accountId: AccountUUID?
    private let logger: HsToolKit.Logger?

    private let poolFiller: SingleUseAddressPoolFiller
    private let historicalScanner: SingleUseHistoricalScanner
    private let activeMonitor: SingleUseActiveMonitor

    private var isFilling = false
    private var subscriptions = Set<AnyCancellable>()

    private let addressesSubject = PassthroughSubject<[SingleUseAddress], Never>()
    nonisolated var addressesPublisher: AnyPublisher<[SingleUseAddress], Never> {
        addressesSubject.eraseToAnyPublisher()
    }

    private let handleNewUsedAddressSubject = PassthroughSubject<SingleUseAddress, Never>()
    nonisolated var handleNewUsedAddressPublisher: AnyPublisher<SingleUseAddress, Never> {
        handleNewUsedAddressSubject.eraseToAnyPublisher()
    }

    // Current addresses snapshot
    func addresses() throws -> [SingleUseAddress] {
        try storage.all(walletId: walletId)
    }

    // Get first nonused
    func firstUnused() throws -> SingleUseAddress? {
        try storage.firstUnused(walletId: walletId)
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

        poolFiller = SingleUseAddressPoolFiller(
            synchronizer: synchronizer,
            storage: storage,
            walletId: walletId,
            logger: logger
        )

        historicalScanner = SingleUseHistoricalScanner(
            synchronizer: synchronizer,
            storage: storage,
            walletId: walletId,
            logger: logger
        )

        activeMonitor = SingleUseActiveMonitor(
            synchronizer: synchronizer,
            storage: storage,
            walletId: walletId,
            logger: logger
        )

        logger?.log(level: .debug, message: "SingleUseAddressManager: Initialized")

        // Subscribe to worker events
        Task {
            await subscribeToEvents()
        }
    }

    func set(accountId: AccountUUID) async {
        self.accountId = accountId
        await poolFiller.set(accountId: accountId)
    }

    func start() async {
        logger?.log(level: .debug, message: "SingleUseAddressManager: start()")
        await fillSingleUseAddresses()
    }

    func stop() async {
        logger?.log(level: .debug, message: "SingleUseAddressManager: stop()")

        await historicalScanner.stop()
        await activeMonitor.stop()

        logger?.log(level: .debug, message: "SingleUseAddressManager: Stopped")
    }

    func fillSingleUseAddresses() async {
        // If already filling, skip this call
        guard !isFilling else {
            logger?.log(level: .debug, message: "SingleUseAddressManager: fillSingleUseAddresses() - Already in progress, skipping")
            return
        }

        isFilling = true
        defer { isFilling = false }

        logger?.log(level: .debug, message: "SingleUseAddressManager: fillSingleUseAddresses() - START")

        // 1. Check SDK for new used addresses
        do {
            try await checkAndUpdateUsedAddresses()
        } catch {
            logger?.log(level: .error, message: "SingleUseAddressManager: Generation failed: \(error)")
        }

        // 2. Generate new addresses (will stop at gap limit, no duplicates)
        do {
            let generated = try await poolFiller.fill()
            logger?.log(level: .debug, message: "SingleUseAddressManager: Generated \(generated) addresses")
        } catch {
            logger?.log(level: .error, message: "SingleUseAddressManager: Generation failed: \(error)")
        }

        // 3. Get current lastUsed
        let lastUsed = try? storage.lastUsedAddress(walletId: walletId)

        logger?.log(level: .debug, message: "SingleUseAddressManager: Current lastUsed: \(lastUsed?.address ?? "N/A | FIRST TIME GENERATED")")

        await historicalScanner.update(lastUsed: lastUsed)
        await activeMonitor.update(lastUsed: lastUsed)

        logger?.log(level: .debug, message: "SingleUseAddressManager: fillSingleUseAddresses() - COMPLETE")
    }

    private func subscribeToEvents() async {
        // Subscribe to HistoricalScanner events
        await historicalScanner.events.sink { [weak self] event in
            guard let self else { return }

            Task {
                await self.handleHistoricalScannerEvent(event)
            }
        }.store(in: &subscriptions)

        await activeMonitor.events.sink { [weak self] event in
            guard let self else { return }

            Task {
                await self.handleActiveMonitorEvent(event)
            }
        }.store(in: &subscriptions)

        logger?.log(level: .debug, message: "SingleUseAddressManager: Subscribed to worker events")
    }

    private func handleHistoricalScannerEvent(_ event: SingleUseHistoricalScanner.ScannerEvent) async {
        switch event {
        case let .addressMarkedAsUsed(address):
            logger?.log(level: .debug, message: "SingleUseAddressManager: HistoricalScanner found used: \(address.address)")
            // Just log, no action needed - scanner continues working
        }
    }

    private func handleActiveMonitorEvent(_ event: SingleUseActiveMonitor.MonitorEvent) async {
        switch event {
        case let .newUsedAddressFound(address):
            logger?.log(level: .debug, message: "SingleUseAddressManager: 🔥 ActiveMonitor found new used: \(address.address)")
            handleNewUsedAddressSubject.send(address)

            // ActiveMonitor already stopped itself and marked address as used
            // Restart fill process to generate new addresses and update workers
            await fillSingleUseAddresses()
        }
    }

    private func checkAndUpdateUsedAddresses() async throws {
        guard let accountId else {
            throw AddressError.noAccountId
        }

        logger?.log(level: .debug, message: "SingleUseAddressManager: checkAndUpdateUsedAddresses() - START")

        do {
            let result = try await synchronizer.checkSingleUseTransparentAddresses(accountUUID: accountId)

            logger?.log(level: .debug, message: "SingleUseAddressManager: checkSingleUseTransparentAddresses result: \(result)")

            switch result {
            case let .found(addressString):
                logger?.log(level: .debug, message: "SingleUseAddressManager: SDK found last used address: \(addressString)")

                // Check if address exists in storage
                if var existingAddress = try? storage.address(addressString, walletId: walletId) {
                    if !existingAddress.isUsed {
                        logger?.log(level: .debug, message: "SingleUseAddressManager: Marking address as USED: \(addressString)")

                        existingAddress.markAsUsed()
                        try? storage.update(address: existingAddress)
                    } else {
                        logger?.log(level: .debug, message: "SingleUseAddressManager: Address already marked as used: \(addressString)")
                    }
                } else {
                    logger?.log(level: .warning, message: "SingleUseAddressManager: SDK returned used address not in storage: \(addressString)")
                }

            case .notFound:
                logger?.log(level: .debug, message: "SingleUseAddressManager: SDK found no used addresses")

            case .torRequired:
                logger?.log(level: .warning, message: "SingleUseAddressManager: Tor must be enabled for address check")
            }

        } catch {
            logger?.log(level: .error, message: "SingleUseAddressManager: checkAndUpdateUsedAddresses error: \(error)")
        }

        logger?.log(level: .debug, message: "SingleUseAddressManager: checkAndUpdateUsedAddresses() - COMPLETE")
    }
}

extension SingleUseAddressManager {
    enum AddressError: LocalizedError {
        case noAccountId

        var errorDescription: String? {
            switch self {
            case .noAccountId:
                return "SingleUseAddressManager: AccountId not setted"
            }
        }
    }
}
