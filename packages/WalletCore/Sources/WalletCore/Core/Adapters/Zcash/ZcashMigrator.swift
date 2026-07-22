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
                            },
                        ],
                        alignment: .horizontal)),
                ]
            )
        }
    }
}
