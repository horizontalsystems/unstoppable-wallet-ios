import Foundation
import HsToolKit
import ZcashLightClientKit

class ZcashMigrator {
    // kill-switch for the Orchard → Ironwood migration flow. Flip to true together with the testnet
    // E2E once the send-max migration is validated end to end.
    // TEMPORARILY true for testnet debugging — revert to false before release.
    static let migrationEnabled = true

    private let uniqueId: String
    private let threshold: Decimal
    private let network: ZcashNetwork
    private let storage: ZcashAdapterStorage
    private let logger: HsToolKit.Logger?

    var engine: IZcashMigrationEngine?

    private var alertShown = false

    init(uniqueId: String, threshold: Decimal, network: ZcashNetwork, storage: ZcashAdapterStorage, logger: HsToolKit.Logger?) {
        self.uniqueId = uniqueId
        self.threshold = threshold
        self.network = network
        self.storage = storage
        self.logger = logger
    }

    func clearOnWipe() {
        try? storage.deleteMigrationTxs(accountId: uniqueId)
    }

    // per-call GRDB read, no cache: the table holds a handful of rows, record mapping is paginated,
    // and dbPool is thread-safe by itself (same pattern as the shielding alertState reads)
    func isMigrationTx(hash: String) -> Bool {
        ((try? storage.migrationTxIds(accountId: uniqueId)) ?? []).contains(hash)
    }

    // history marker only: a row lets `isMigrationTx` label the self-send in transaction history.
    // send-max is a normal transaction, so there is no privacy buffer to track here.
    private func save(txId: String?) {
        guard let txId, !isMigrationTx(hash: txId) else {
            return
        }
        try? storage.save(migrationTx: ZcashMigrationTx(txId: txId, accountId: uniqueId, createdAt: Date()))
    }

    // The NU6.3 (Ironwood) activation height for the wallet's network. In DEBUG, when the
    // "Emulate ZEC Migration" toggle is on, mainnet is forced to a low height so the migration flow
    // can be exercised on mainnet; otherwise the real SDK/FFI activation height is used.
    var activationHeight: BlockHeight? {
        #if DEBUG
            if Core.shared.localStorage.emulateZcashMigration, network.networkType == .mainnet {
                return 3_420_000
            }
        #endif
        // NU6.3 (Ironwood) activation heights, from zcash_protocol consensus (the SDK reads the same
        // values via the rust FFI, which the official prebuilt binary doesn't surface to Swift).
        switch network.networkType {
        case .mainnet: return 3_428_143
        case .testnet: return 4_134_000
        default: return nil
        }
    }

    func ironwoodActive(latestHeight: Int) -> Bool {
        guard let activationHeight else {
            return false
        }
        return latestHeight >= activationHeight
    }

    func handleCheck(orchardBalance: Decimal, latestHeight: Int, syncStatus: SyncStatus?) -> Bool {
        // Only the active account's adapter may surface the global migration alert. An adapter from a
        // previously-selected account can outlive the switch (async synchronizer teardown) and fire a
        // late balance/state update — it must not present the sheet over the now-active account.
        guard Core.shared.accountManager.activeAccount?.id == uniqueId else {
            return false
        }

        guard let syncStatus else {
            return false
        }

        guard Self.isMigrationSuggestionNeeded(
            migrationEnabled: Self.migrationEnabled,
            ironwoodActive: ironwoodActive(latestHeight: latestHeight),
            syncStatus: syncStatus,
            orchardSpendable: orchardBalance,
            threshold: threshold,
            alertShown: alertShown
        ) else {
            return false
        }

        alertShown = true
        logger?.log(level: .debug, message: "Orchard funds pending migration: \(orchardBalance), showing migration alert")
        showAlert()
        return true
    }

    // After a broadcast the swept notes become pending-spent, so orchardSpendable drops below the
    // threshold and the predicate is false on its own — no timestamp-based suppression needed.
    static func isMigrationSuggestionNeeded(migrationEnabled: Bool, ironwoodActive: Bool, syncStatus: SyncStatus,
                                            orchardSpendable: Decimal, threshold: Decimal, alertShown: Bool) -> Bool
    {
        guard migrationEnabled, ironwoodActive, !alertShown, syncStatus == .upToDate else {
            return false
        }
        return orchardSpendable > threshold
    }

    // read for the confirmation screen: fee is authoritative from the proposal, amount is the swept
    // shielded balance minus that fee. `performMigration` re-proposes before broadcasting.
    func migrationProposal(orchardBalance: Decimal) async throws -> (amount: Decimal, fee: Decimal) {
        guard let engine else {
            throw AppError.ZcashError.noAccountId
        }

        let fee = try await engine.estimatedFee().decimalValue.decimalValue
        let amount = orchardBalance - fee
        guard amount > 0 else {
            throw AppError.ZcashError.notEnough
        }
        return (amount: amount, fee: fee)
    }

    // send-max sweep to the wallet's own UA. Runs as an ordinary send (the adapter wraps it in its
    // send critical section); no stop-sync, no privacy buffer. Returns the broadcast txid.
    func performMigration() async throws -> String? {
        guard let engine else {
            throw AppError.ZcashError.noAccountId
        }

        let txId = try await engine.migrate()
        save(txId: txId)
        logger?.log(level: .debug, message: "Migration broadcast done, txId: \(txId ?? "unrecorded")")
        return txId
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
