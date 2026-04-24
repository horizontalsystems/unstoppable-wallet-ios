import BigInt
import Combine
import EvmKit
import Foundation
import GRDB
import MarketKit

// Central orchestrator of AA-wallet lifecycle. Owns aa.sqlite DatabasePool, runs migrator,
// subscribes to AccountManager.accountDeletedPublisher for cascade cleanup, performs
// startup orphan repair.
//
// Threading contract: public API called from main thread. Subscriber callback runs on
// whatever queue AccountManager emits on (today: main) — GRDB DatabasePool is thread-safe.
class SmartAccountManager {
    private let accountManager: AccountManager
    private let profileStorage: SmartAccountProfileRecordStorage
    private let deploymentStorage: SmartAccountDeploymentRecordStorage
    private let pendingOpStorage: PendingUserOperationRecordStorage
    private var cancellables = Set<AnyCancellable>()

    init(accountManager: AccountManager, databaseDirectoryUrl: URL) throws {
        let dbUrl = databaseDirectoryUrl.appendingPathComponent("aa.sqlite")
        let dbPool = try DatabasePool(path: dbUrl.path)

        try AaStorageMigrator.migrate(dbPool: dbPool)

        self.accountManager = accountManager
        profileStorage = SmartAccountProfileRecordStorage(dbPool: dbPool)
        deploymentStorage = SmartAccountDeploymentRecordStorage(dbPool: dbPool)
        pendingOpStorage = PendingUserOperationRecordStorage(dbPool: dbPool)

        do {
            try repairOrphanedProfiles()
        } catch {
            print("[SmartAccountManager] orphan repair failed: \(error) — skipping, will retry next launch")
        }

        accountManager.accountDeletedPublisher
            .sink { [weak self] account in
                try? self?.handleAccountDeleted(account: account)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Profile operations

extension SmartAccountManager {
    func createProfile(account: Account) throws -> SmartAccountProfile {
        guard case let .passkeyOwned(_, publicKeyX, publicKeyY) = account.type else {
            throw SmartAccountError.invalidAccountType
        }

        if let existingRecord = try profileStorage.profile(accountId: account.id) {
            let existing = try SmartAccountProfile(record: existingRecord)
            guard existing.ownerPublicKeyX == publicKeyX, existing.ownerPublicKeyY == publicKeyY else {
                throw SmartAccountError.pubkeyMismatch
            }
            return existing
        }

        let address = try BarzAddressResolver.resolveLocally(
            publicKeyX: publicKeyX,
            publicKeyY: publicKeyY,
            blockchainType: .ethereum
        )

        let profile = SmartAccountProfile(
            id: UUID().uuidString,
            accountId: account.id,
            address: address,
            implementationVersion: "barz_v1_0_0",
            ownerPublicKeyX: publicKeyX,
            ownerPublicKeyY: publicKeyY,
            salt: 0,
            createdAt: Date().timeIntervalSince1970
        )

        try profileStorage.save(record: profile.toRecord())
        return profile
    }

    func profile(id: String) throws -> SmartAccountProfile? {
        guard let record = try profileStorage.profile(id: id) else { return nil }
        return try SmartAccountProfile(record: record)
    }

    func profile(accountId: String) throws -> SmartAccountProfile? {
        guard let record = try profileStorage.profile(accountId: accountId) else { return nil }
        return try SmartAccountProfile(record: record)
    }

    func profiles() throws -> [SmartAccountProfile] {
        try profileStorage.all().map { try SmartAccountProfile(record: $0) }
    }
}

// MARK: - Deployment operations

extension SmartAccountManager {
    func createDeployment(profile: SmartAccountProfile, blockchainType: BlockchainType) throws -> SmartAccountDeployment {
        if let existingRecord = try deploymentStorage.deployment(profileId: profile.id, blockchainType: blockchainType.uid) {
            return SmartAccountDeployment(record: existingRecord)
        }

        let deployment = SmartAccountDeployment(
            id: UUID().uuidString,
            profileId: profile.id,
            blockchainType: blockchainType,
            implementationVersion: profile.implementationVersion,
            isDeployed: false,
            preferredPaymaster: "pimlico",
            activatedAt: Date().timeIntervalSince1970
        )

        try deploymentStorage.save(record: deployment.toRecord())
        return deployment
    }

    func deployment(profileId: String, blockchainType: BlockchainType) throws -> SmartAccountDeployment? {
        guard let record = try deploymentStorage.deployment(profileId: profileId, blockchainType: blockchainType.uid) else { return nil }
        return SmartAccountDeployment(record: record)
    }

    func deployments(profileId: String) throws -> [SmartAccountDeployment] {
        try deploymentStorage.deployments(profileId: profileId).map { SmartAccountDeployment(record: $0) }
    }

    func updateDeployed(deployment: SmartAccountDeployment, isDeployed: Bool) throws {
        try deploymentStorage.updateDeployed(id: deployment.id, isDeployed: isDeployed)
    }
}

// MARK: - Lifecycle / admin

extension SmartAccountManager {
    func clearAll() throws {
        // FK cascade kills deployments + pendingOps.
        try profileStorage.clear()
    }
}

// MARK: - Private

private extension SmartAccountManager {
    func repairOrphanedProfiles() throws {
        let records = try profileStorage.all()
        // Use allAccounts (unfiltered) — accounts is filtered by current passcode level
        // (duress mode), which would incorrectly make hidden-account profiles look orphaned.
        let existingAccountIds = Set(accountManager.allAccounts.map(\.id))

        var removed = 0
        for record in records where !existingAccountIds.contains(record.accountId) {
            try profileStorage.delete(id: record.id)
            removed += 1
        }
        if removed > 0 {
            print("[SmartAccountManager] startup repair removed \(removed) orphaned profile(s)")
        }
    }

    func handleAccountDeleted(account: Account) throws {
        try profileStorage.delete(accountId: account.id)
    }
}

extension SmartAccountManager {
    enum SmartAccountError: Error, Equatable {
        case invalidAccountType
        case pubkeyMismatch
    }
}
