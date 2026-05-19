import BigInt
import Combine
import EvmKit
import Foundation
import GRDB
import MarketKit
import TronKit
import WalletCore

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
    private let gasFreeProfileStorage: GasFreeProfileRecordStorage
    private let pendingGasFreeStorage: PendingGasFreeTransferRecordStorage
    private var cancellables = Set<AnyCancellable>()

    init(accountManager: AccountManager, databaseDirectoryUrl: URL) throws {
        let dbUrl = databaseDirectoryUrl.appendingPathComponent("aa.sqlite")
        let dbPool = try DatabasePool(path: dbUrl.path)

        try AaStorageMigrator.migrate(dbPool: dbPool)

        self.accountManager = accountManager
        profileStorage = SmartAccountProfileRecordStorage(dbPool: dbPool)
        deploymentStorage = SmartAccountDeploymentRecordStorage(dbPool: dbPool)
        pendingOpStorage = PendingUserOperationRecordStorage(dbPool: dbPool)
        gasFreeProfileStorage = GasFreeProfileRecordStorage(dbPool: dbPool)
        pendingGasFreeStorage = PendingGasFreeTransferRecordStorage(dbPool: dbPool)

        do {
            try repairOrphanedProfiles()
        } catch {
            print("[SmartAccountManager] orphan repair failed: \(error) — skipping, will retry next launch")
        }

        accountManager.accountDeletedPublisher
            .sink { [weak self] account in
                do {
                    try self?.handleAccountDeleted(account: account)
                } catch {
                    print("[SmartAccountManager] account-deleted cleanup failed for \(account.id): \(error) — orphan will be cleaned by startup repair")
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Profile operations

extension SmartAccountManager {
    func createProfile(
        account: Account,
        ownerPublicKeyX: Data,
        ownerPublicKeyY: Data,
        curve: SignatureCurve
    ) throws -> SmartAccountProfile {
        guard case .passkeyOwned = account.type else {
            throw SmartAccountError.invalidAccountType
        }

        if let existingRecord = try profileStorage.profile(accountId: account.id) {
            let existing = try SmartAccountProfile(record: existingRecord)
            guard existing.ownerPublicKeyX == ownerPublicKeyX,
                  existing.ownerPublicKeyY == ownerPublicKeyY,
                  existing.curve == curve
            else {
                throw SmartAccountError.pubkeyMismatch
            }
            return existing
        }

        let profile = SmartAccountProfile(
            id: UUID().uuidString,
            accountId: account.id,
            implementationVersion: curve.implementationVersion,
            ownerPublicKeyX: ownerPublicKeyX,
            ownerPublicKeyY: ownerPublicKeyY,
            curve: curve,
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

// MARK: - Pending UserOperation operations

extension SmartAccountManager {
    func savePendingOperation(record: PendingUserOperationRecord) throws {
        try pendingOpStorage.save(record: record)
    }
}

// MARK: - Pending GasFree transfers

extension SmartAccountManager {
    func savePendingGasFreeTransfer(record: PendingGasFreeTransferRecord) throws {
        try pendingGasFreeStorage.save(record: record)
    }

    func pendingGasFreeTransfers(status: String) throws -> [PendingGasFreeTransferRecord] {
        try pendingGasFreeStorage.transfers(status: status)
    }

    func updatePendingGasFreeTransfer(traceId: String, status: String, txnHash: String?, lastPolledAt: TimeInterval?) throws {
        try pendingGasFreeStorage.update(traceId: traceId, status: status, txnHash: txnHash, lastPolledAt: lastPolledAt)
    }

    func deletePendingGasFreeTransfer(traceId: String) throws {
        try pendingGasFreeStorage.delete(traceId: traceId)
    }
}

// MARK: - GasFree operations

extension SmartAccountManager {
    func gasFreeProfile(accountId: String) throws -> GasFreeProfile? {
        guard let record = try gasFreeProfileStorage.profile(accountId: accountId) else {
            return nil
        }
        return try GasFreeProfile(record: record)
    }

    /// Idempotent: returns existing profile if already created (controllerAddress must match);
    /// otherwise derives `gasFreeAddress` locally and saves a new record. v1 hardcodes the
    /// mainnet service provider + verifying contract from `GasFreeChainAddresses`.
    func createGasFreeProfile(account: Account, controllerAddress: TronKit.Address) throws -> GasFreeProfile {
        guard case .passkeyOwned = account.type else {
            throw SmartAccountError.invalidAccountType
        }

        if let existing = try gasFreeProfile(accountId: account.id) {
            guard existing.controllerAddress == controllerAddress else {
                throw SmartAccountError.controllerMismatch
            }
            return existing
        }

        let gasFreeAddress = try GasFreeAddressResolver.resolveLocally(userAddress: controllerAddress)

        let profile = GasFreeProfile(
            accountId: account.id,
            controllerAddress: controllerAddress,
            gasFreeAddress: gasFreeAddress,
            providerId: GasFreeChainAddresses.mainnetServiceProvider,
            verifyingContract: GasFreeChainAddresses.mainnetFactory,
            implementationVersion: GasFreeChainAddresses.v1ImplementationVersion,
            createdAt: Date().timeIntervalSince1970,
            lastVerifiedAt: nil
        )

        try gasFreeProfileStorage.save(record: profile.toRecord())
        return profile
    }
}

// MARK: - Lifecycle / admin

extension SmartAccountManager {
    func clearAll() throws {
        // FK cascade kills deployments + pendingOps.
        try profileStorage.clear()
        try gasFreeProfileStorage.deleteAll()
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
        try gasFreeProfileStorage.delete(accountId: account.id)
    }
}

extension SmartAccountManager {
    /// True when the account is funded by a paymaster / gas-token mechanism (ERC-4337 Barz on EVM,
    /// GasFree on Tron). Such accounts don't require holding the chain's native gas token to send.
    /// `.passkeyOwned` is the only AccountType this initiative provisions; the predicate is kept
    /// in the Abstraction module so this entire concern stays portable to other projects.
    static func isGasTokenPayment(_ accountType: AccountType) -> Bool {
        if case .passkeyOwned = accountType { return true }
        return false
    }

    /// Single-call routing predicate for the Send-flow: a (account, token) pair is eligible for
    /// the GasFree (Tron) send-pipeline. Encapsulates the AND of "account uses gas-token payment"
    /// and "token is a registered v1 stablecoin on Tron" so callers in `Modules/SendNew/` ask one
    /// question instead of composing AA-specific predicates themselves.
    static func canUseGasFree(account: Account, token: Token) -> Bool {
        guard isGasTokenPayment(account.type),
              token.blockchainType == .tron,
              case let .eip20(tokenHex) = token.type
        else {
            return false
        }
        return StablecoinRegistry.supports(blockchainType: .tron, tokenAddress: tokenHex)
    }
}

extension SmartAccountManager {
    enum SmartAccountError: Error, Equatable {
        case invalidAccountType
        case pubkeyMismatch
        case controllerMismatch
    }
}
