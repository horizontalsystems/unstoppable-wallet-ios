import Foundation
import HsExtensions
import HsToolKit
import RxSwift
import ZcashLightClientKit

class ZcashBalanceService {
    private let uniqueId: String
    private let storage: ZcashAdapterStorage
    private let migrator: ZcashMigrator
    private let logger: HsToolKit.Logger?

    private let balanceSubject = PublishSubject<BalanceData>()

    weak var syncService: ZcashSyncService?

    @PostPublished var zCashBalanceData: ZcashBalanceData {
        didSet {
            balanceSubject.onNext(zCashBalanceData.balanceData)
        }
    }

    init(uniqueId: String, storage: ZcashAdapterStorage, migrator: ZcashMigrator, logger: HsToolKit.Logger?) throws {
        self.uniqueId = uniqueId
        self.storage = storage
        self.migrator = migrator
        self.logger = logger

        zCashBalanceData = try storage.balanceData(id: uniqueId) ?? .empty(id: uniqueId)
    }

    var balanceData: BalanceData {
        zCashBalanceData.balanceData
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceSubject.asObservable()
    }

    func sync(synchronizerState: SynchronizerState?, accountId: AccountUUID?, lastBlockHeight: Int) {
        guard let synchronizerState, let accountId, let visible = synchronizerState.accountsBalances[accountId] else {
            zCashBalanceData = (try? storage.balanceData(id: uniqueId)) ?? .empty(id: uniqueId)
            return
        }

        let local = synchronizerState.localAccountsBalances[accountId].map(Inputs.init(balance:))
        let balanceData = Self.compose(
            id: uniqueId,
            local: local,
            visible: Inputs(balance: visible),
            isSpendableMasked: synchronizerState.isSpendableMasked,
            isRecovering: synchronizerState.isRecovering,
            previous: zCashBalanceData
        )
        logger?.log(level: .debug, message: "Balance from syncer: full=\(balanceData.full) available=\(balanceData.available) transparent=\(balanceData.transparent) masked=\(synchronizerState.isSpendableMasked) recovering=\(synchronizerState.isRecovering)")

        update(balanceData: balanceData, syncStatus: synchronizerState.syncStatus, lastBlockHeight: lastBlockHeight)
    }

    private func update(balanceData: ZcashBalanceData, syncStatus: SyncStatus, lastBlockHeight: Int) {
        let oldTransparent = zCashBalanceData.transparent

        if balanceData != zCashBalanceData {
            zCashBalanceData = balanceData
            do {
                try storage.save(balanceData: balanceData)
                logger?.log(level: .debug, message: "Saved balance: transparent=\(balanceData.transparent)")
            } catch {
                logger?.log(level: .warning, message: "Failed to save balance to DB: \(error)")
            }
        }

        // migration takes precedence over shielding: at most one alert per update
        let migrationSuggested = migrator.handleCheck(orchardBalance: balanceData.orchard, latestHeight: lastBlockHeight, syncStatus: syncStatus)

        if !migrationSuggested {
            handleTransparentUpdates(oldBalance: oldTransparent, newBalance: balanceData.transparent, syncStatus: syncStatus)
        }
    }

    private func handleTransparentUpdates(oldBalance _: Decimal, newBalance: Decimal, syncStatus: SyncStatus) {
        // handle only after syncing adapter
        guard syncStatus == .upToDate else {
            return
        }

        let alertState = try? storage.alertState(id: uniqueId)
        let lastAlerted = alertState?.lastAlertedBalance ?? 0

        if newBalance <= ZcashAdapter.minimalThreshold, lastAlerted > 0 {
            let resetState = ZcashTransparentAlertState(id: uniqueId, lastAlertedBalance: 0)
            try? storage.save(state: resetState)
            return
        }

        // show alert only when new
        if newBalance > lastAlerted, newBalance > ZcashAdapter.minimalThreshold {
            logger?.log(level: .debug, message: "Received transparent funds: \(lastAlerted) → \(newBalance), showing shielding alert")
            showShieldingAlert(balance: newBalance)

            let newState = ZcashTransparentAlertState(id: uniqueId, lastAlertedBalance: newBalance)
            try? storage.save(state: newState)
        }
    }

    private func showShieldingAlert(balance: Decimal) {
        let ownAddress = syncService?.uAddress?.stringEncoded
        DispatchQueue.main.async {
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                BottomSheetView(
                    items: [
                        .title(icon: ThemeImage.shieldOff, title: "balance.token.transparent.detected.title".localized),
                        .text(text: "balance.token.transparent.detected.description".localized),
                        .buttonGroup(.init(buttons: [
                                .init(style: .gray, title: "button.cancel".localized) {
                                    isPresented.wrappedValue = false
                                },
                                .init(style: .yellow, title: "balance.token.shield".localized) {
                                    isPresented.wrappedValue = false

                                    Coordinator.shared.present { _ in
                                        ThemeNavigationStack {
                                            ShieldSendView(amount: balance, address: ownAddress)
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
}

extension ZcashBalanceService {
    struct Inputs: Equatable {
        let shieldedTotal: Zatoshi
        let shieldedSpendable: Zatoshi
        let unshielded: Zatoshi
        let awaitingResolution: Zatoshi
        let orchardSpendable: Zatoshi

        init(shieldedTotal: Zatoshi, shieldedSpendable: Zatoshi, unshielded: Zatoshi, awaitingResolution: Zatoshi, orchardSpendable: Zatoshi) {
            self.shieldedTotal = shieldedTotal
            self.shieldedSpendable = shieldedSpendable
            self.unshielded = unshielded
            self.awaitingResolution = awaitingResolution
            self.orchardSpendable = orchardSpendable
        }

        init(balance: AccountBalance) {
            self.init(
                shieldedTotal: balance.shieldedTotal(),
                shieldedSpendable: balance.shieldedSpendableValue,
                unshielded: balance.unshielded,
                awaitingResolution: balance.awaitingResolution,
                orchardSpendable: balance.orchardBalance.spendableValue
            )
        }
    }

    // Totals from the unmasked local snapshot (recovery: from the engine-reconciled visible one),
    // spendable only when the SDK is willing to state it — otherwise the cached value stays.
    static func compose(id: String, local: Inputs?, visible: Inputs, isSpendableMasked: Bool, isRecovering: Bool, previous: ZcashBalanceData) -> ZcashBalanceData {
        let totals = (isRecovering ? nil : local) ?? visible
        let available = isSpendableMasked ? previous.available : visible.shieldedSpendable.decimalValue.decimalValue

        return ZcashBalanceData(
            id: id,
            full: totals.shieldedTotal.decimalValue.decimalValue,
            available: available,
            transparent: (totals.unshielded + totals.awaitingResolution).decimalValue.decimalValue,
            orchard: totals.orchardSpendable.decimalValue.decimalValue
        )
    }
}
