import Combine
import Foundation
import ZcashLightClientKit

protocol IZcashMigrationEngine: AnyObject {
    func state() async throws -> MigrationState
    func proposeImmediate() async throws -> MigrationSchedule
    func signAndStore(schedule: MigrationSchedule) async throws
    func executeNext(options: MigrationNetworkPrivacyOptions) async throws -> MigrationTransferResult?
    func isSyncBlocked() async -> Bool
    var syncBlockedStream: AnyPublisher<Bool, Never> { get }
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

    // CurrentValueSubject-backed with an internal SDK ticker: pushes false when the privacy buffer expires
    var syncBlockedStream: AnyPublisher<Bool, Never> {
        synchronizer.migrationSyncBlockedStream
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
        var stateOverride: MigrationState?
        var executeThrowsRecordFailed = false
        private(set) var signedSchedule: MigrationSchedule?
        private(set) var executedTxIds = [String]()
        private var lastExecuteAt: Date?
        private let blockedSubject: CurrentValueSubject<Bool, Never>

        // migratedAt (the latest stored migration row) makes the fake honest across relaunches:
        // migrated → zero balance, gate blocked while inside the privacy window
        init(orchardSpendable: Zatoshi = Zatoshi(100_000_000), executeResults: [MigrationTransferResult] = [], migratedAt: Date? = nil) {
            self.orchardSpendable = migratedAt == nil ? orchardSpendable : Zatoshi(0)
            self.executeResults = executeResults
            lastExecuteAt = migratedAt

            let remaining = migratedAt.map { ZcashMigrator.bufferInterval - Date().timeIntervalSince($0) } ?? 0
            blockedSubject = CurrentValueSubject(remaining > 0)
            if remaining > 0 {
                scheduleGateRelease(after: remaining)
            }
        }

        // mirrors the SDK gate ticker: pushes false when the emulated buffer expires
        private func scheduleGateRelease(after seconds: TimeInterval) {
            Task { [weak self] in
                try? await Task.sleep(seconds: seconds)
                self?.blockedSubject.send(false)
            }
        }

        func state() async throws -> MigrationState {
            if let stateOverride {
                return stateOverride
            }
            if lastExecuteAt != nil {
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
            if executeThrowsRecordFailed {
                lastExecuteAt = Date()
                signedSchedule = nil
                throw ZcashError.migrationRecordFailedAfterBroadcast(NSError(domain: "fake", code: 0))
            }
            guard signedSchedule != nil else {
                return nil
            }

            let result = executeResults.isEmpty ? .success(txId: Self.fakeTxId()) : executeResults.removeFirst()
            if case let .success(txId) = result {
                executedTxIds.append(txId)
                signedSchedule = nil
                orchardSpendable = Zatoshi(0)
                lastExecuteAt = Date()
                blockedSubject.send(true)
                scheduleGateRelease(after: ZcashMigrator.bufferInterval)
            }
            return result
        }

        // mirrors the SDK gate: blocked while a signed transfer is pending or within the privacy buffer after broadcast
        func isSyncBlocked() async -> Bool {
            if signedSchedule != nil {
                return true
            }
            if let lastExecuteAt {
                return Date().timeIntervalSince(lastExecuteAt) < ZcashMigrator.bufferInterval
            }
            return false
        }

        var syncBlockedStream: AnyPublisher<Bool, Never> {
            blockedSubject.eraseToAnyPublisher()
        }

        func restart() async throws {
            signedSchedule = nil
        }

        private static func fakeTxId() -> String {
            (UUID().uuidString + UUID().uuidString).replacingOccurrences(of: "-", with: "").lowercased()
        }
    }
#endif
