import Foundation
import HsToolKit
import ZcashLightClientKit

class ZcashMigrator {
    static let migrationEnabled = true // kill-switch for the Orchard → Ironwood migration flow
    static let bufferInterval: TimeInterval = 600 // mirrors the SDK-enforced post-broadcast privacy window

    private let uniqueId: String
    private let threshold: Decimal
    private let network: ZcashNetwork
    private let logger: HsToolKit.Logger?

    var engine: IZcashMigrationEngine?

    private var alertShown = false

    private var timestampKey: String { "zcash-migration-timestamp-\(uniqueId)" }

    var timestamp: Date? {
        get { Core.shared.userDefaultsStorage.value(for: timestampKey) }
        set { Core.shared.userDefaultsStorage.set(value: newValue, for: timestampKey) }
    }

    // UI countdown only; the authority on whether sync is actually blocked is the SDK gate
    var remainingBufferMinutes: Int? {
        guard let timestamp else {
            return nil
        }

        let remaining = timestamp.addingTimeInterval(Self.bufferInterval).timeIntervalSinceNow
        guard remaining > 0 else {
            return nil
        }
        return Int((remaining / 60).rounded(.up))
    }

    init(uniqueId: String, threshold: Decimal, network: ZcashNetwork, logger: HsToolKit.Logger?) {
        self.uniqueId = uniqueId
        self.threshold = threshold
        self.network = network
        self.logger = logger
    }

    private func ironwoodActive(latestHeight: Int) -> Bool {
        guard let activationHeight = network.ironwoodActivationHeight else {
            return false
        }
        return latestHeight >= activationHeight
    }

    func handleCheck(orchardBalance: Decimal, latestHeight: Int, syncStatus: SyncStatus?) -> Bool {
        guard let syncStatus else {
            return false
        }

        guard Self.isMigrationSuggestionNeeded(
            migrationEnabled: Self.migrationEnabled,
            ironwoodActive: ironwoodActive(latestHeight: latestHeight),
            syncStatus: syncStatus,
            orchardSpendable: orchardBalance,
            threshold: threshold,
            alertShown: alertShown,
            migrationTimestamp: timestamp,
            now: Date()
        ) else {
            return false
        }

        alertShown = true
        logger?.log(level: .debug, message: "Orchard funds pending migration: \(orchardBalance), showing migration alert")
        showAlert()
        return true
    }

    static func isMigrationSuggestionNeeded(migrationEnabled: Bool, ironwoodActive: Bool, syncStatus: SyncStatus, orchardSpendable: Decimal,
                                            threshold: Decimal, alertShown: Bool, migrationTimestamp: Date?, now: Date) -> Bool
    {
        guard migrationEnabled, ironwoodActive, !alertShown, syncStatus == .upToDate else {
            return false
        }
        guard orchardSpendable > threshold else {
            return false
        }
        if let migrationTimestamp, now < migrationTimestamp.addingTimeInterval(bufferInterval) {
            return false
        }
        return true
    }

    // pure read for the confirmation screen; the session re-proposes before signing
    func migrationProposal(orchardBalance: Decimal) async throws -> (amount: Decimal, fee: Decimal) {
        guard let engine else {
            throw AppError.ZcashError.noAccountId
        }

        let schedule = try await engine.proposeImmediate()
        guard let transfer = schedule.transfers.first else {
            throw AppError.ZcashError.notEnough
        }

        let amount = transfer.amount.decimalValue.decimalValue
        return (amount: amount, fee: max(0, orchardBalance - amount))
    }

    // must be called with the synchronizer stopped: sign/execute throw migrationBroadcastDuringSync while sync is live.
    // Returns nil when the broadcast landed but the SDK failed to record it (reconciled by the engine later).
    func performMigration(currentEndpointHost: String) async throws -> String? {
        guard let engine else {
            throw AppError.ZcashError.noAccountId
        }

        // re-propose: the balance may have changed since the confirmation screen
        let schedule = try await engine.proposeImmediate()
        guard !schedule.transfers.isEmpty else {
            throw AppError.ZcashError.notEnough
        }

        try await engine.signAndStore(schedule: schedule)

        let options = MigrationNetworkPrivacyOptions(useTor: false, submissionEndpoint: submissionEndpoint(excludingHost: currentEndpointHost))
        let txId = try await executeWithRetries(engine: engine, options: options)

        timestamp = Date()
        logger?.log(level: .debug, message: "Migration broadcast done, txId: \(txId ?? "unrecorded")")
        return txId
    }

    private func executeWithRetries(engine: IZcashMigrationEngine, options: MigrationNetworkPrivacyOptions) async throws -> String? {
        var attemptsLeft = 2

        while true {
            let result: MigrationTransferResult?
            do {
                result = try await engine.executeNext(options: options)
            } catch ZcashError.migrationRecordFailedAfterBroadcast {
                return nil
            }

            switch result {
            case let .success(txId):
                return txId
            case .networkError(retryable: true) where attemptsLeft > 0:
                attemptsLeft -= 1
                logger?.log(level: .debug, message: "Migration broadcast retry, attempts left: \(attemptsLeft)")
            case .networkError:
                // signed transfer stays pending; reconciliation re-executes it on next adapter start
                throw AppError.zcash(reason: .migrationFailed)
            case .invalidNote, .expired, nil:
                try await engine.restart()
                throw AppError.zcash(reason: .migrationFailed)
            }
        }
    }

    // a broadcast node must differ from the sync node so migration traffic is not correlated with sync traffic;
    // user-added custom nodes are deliberately excluded
    private func submissionEndpoint(excludingHost host: String) -> LightWalletEndpoint {
        let nodes = network.networkType == .mainnet ? ZcashNode.defaultNodes : ZcashNode.defaultTestnetNodes
        let node = nodes.first { $0.url.host != host } ?? nodes[0]
        return ZcashAdapter.endpoint(url: node.url)
    }

    private func showAlert() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.warning, title: "balance.token.migration.detected.title".localized),
                    .text(text: "balance.token.migration.detected.description".localized),
                    .buttonGroup(.init(buttons: [
                            .init(style: .gray, title: "button.cancel".localized) {
                                isPresented.wrappedValue = false
                            },
                            .init(style: .yellow, title: "balance.token.migrate".localized) {
                                isPresented.wrappedValue = false

                                Coordinator.shared.present { _ in
                                    ThemeNavigationStack {
                                        MigrationSendView()
                                    }
                                }
                            },
                        ],
                        alignment: .horizontal)),
                ]
            )
        }
    }
}
