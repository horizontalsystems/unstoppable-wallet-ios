import Foundation
import ZcashLightClientKit

protocol IZcashMigrationEngine: AnyObject {
    func state() async throws -> MigrationState
    func proposeImmediate() async throws -> MigrationSchedule
    func signAndStore(schedule: MigrationSchedule) async throws
    func executeNext(options: MigrationNetworkPrivacyOptions) async throws -> MigrationTransferResult?
    func isSyncBlocked() async -> Bool
    func restart() async throws
}

class ZcashMigrationEngine: IZcashMigrationEngine {
    private let synchronizer: Synchronizer
    private let accountUUID: AccountUUID
    private let spendingKey: UnifiedSpendingKey

    init(synchronizer: Synchronizer, accountUUID: AccountUUID, spendingKey: UnifiedSpendingKey) {
        self.synchronizer = synchronizer
        self.accountUUID = accountUUID
        self.spendingKey = spendingKey
    }

    func state() async throws -> MigrationState {
        try await synchronizer.migrationState(accountUUID: accountUUID)
    }

    func proposeImmediate() async throws -> MigrationSchedule {
        try await synchronizer.proposeImmediateMigration(accountUUID: accountUUID)
    }

    func signAndStore(schedule: MigrationSchedule) async throws {
        try await synchronizer.signAndStoreMigrationSchedule(accountUUID: accountUUID, schedule, usk: spendingKey)
    }

    func executeNext(options: MigrationNetworkPrivacyOptions) async throws -> MigrationTransferResult? {
        try await synchronizer.executeNextPendingMigrationTransfer(accountUUID: accountUUID, options: options)
    }

    func isSyncBlocked() async -> Bool {
        await synchronizer.isMigrationSyncBlocked()
    }

    func restart() async throws {
        _ = try await synchronizer.restartCurrentMigrationStep(accountUUID: accountUUID, includeResidual: false)
    }
}

#if DEBUG
    class FakeZcashMigrationEngine: IZcashMigrationEngine {
        private static let fee = Zatoshi(15000)

        var orchardSpendable: Zatoshi
        var executeResults: [MigrationTransferResult]
        private(set) var signedSchedule: MigrationSchedule?
        private(set) var executedTxIds = [String]()

        init(orchardSpendable: Zatoshi = Zatoshi(100_000_000), executeResults: [MigrationTransferResult] = []) {
            self.orchardSpendable = orchardSpendable
            self.executeResults = executeResults
        }

        func state() async throws -> MigrationState {
            if !executedTxIds.isEmpty {
                return .complete
            }
            return signedSchedule == nil ? .readyToPropose : .inProgress(MigrationProgress(
                completedTransfers: 0, totalTransfers: 1, remainingOrchard: orchardSpendable, nextTransferReadyAtHeight: nil
            ))
        }

        func proposeImmediate() async throws -> MigrationSchedule {
            guard orchardSpendable > Self.fee else {
                return MigrationSchedule(transfers: [], estimatedDurationHours: 0)
            }

            let transfer = MigrationTransferProposal(
                id: UUID().uuidString,
                amount: orchardSpendable - Self.fee,
                anchorHeight: 3_428_143,
                nextExecutableAfterHeight: 3_428_143,
                expiryHeight: 3_428_143 + 288
            )
            return MigrationSchedule(transfers: [transfer], estimatedDurationHours: 0)
        }

        func signAndStore(schedule: MigrationSchedule) async throws {
            signedSchedule = schedule
        }

        func executeNext(options _: MigrationNetworkPrivacyOptions) async throws -> MigrationTransferResult? {
            guard signedSchedule != nil else {
                return nil
            }

            let result = executeResults.isEmpty ? .success(txId: Self.fakeTxId()) : executeResults.removeFirst()
            if case let .success(txId) = result {
                executedTxIds.append(txId)
                signedSchedule = nil
                orchardSpendable = Zatoshi(0)
            }
            return result
        }

        func isSyncBlocked() async -> Bool {
            false
        }

        func restart() async throws {
            signedSchedule = nil
        }

        private static func fakeTxId() -> String {
            (UUID().uuidString + UUID().uuidString).replacingOccurrences(of: "-", with: "").lowercased()
        }
    }
#endif
