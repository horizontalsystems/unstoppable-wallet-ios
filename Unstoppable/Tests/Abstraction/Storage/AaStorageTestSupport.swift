import Foundation
import GRDB
@testable import Unstoppable
@testable import WalletCore

struct AaStorageTestEnvironment {
    let dbPool: DatabasePool
    let profileStorage: SmartAccountProfileRecordStorage
    let deploymentStorage: SmartAccountDeploymentRecordStorage
    let pendingOpStorage: PendingUserOperationRecordStorage
    let gasFreeProfileStorage: GasFreeProfileRecordStorage

    init() throws {
        let dbURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("aa-tests-\(UUID().uuidString).sqlite")
        let pool = try DatabasePool(path: dbURL.path)
        try AaStorageMigrator.migrate(dbPool: pool)

        dbPool = pool
        profileStorage = SmartAccountProfileRecordStorage(dbPool: pool)
        deploymentStorage = SmartAccountDeploymentRecordStorage(dbPool: pool)
        pendingOpStorage = PendingUserOperationRecordStorage(dbPool: pool)
        gasFreeProfileStorage = GasFreeProfileRecordStorage(dbPool: pool)
    }

    func makeProfile(
        id: String = UUID().uuidString,
        accountId: String = UUID().uuidString
    ) -> SmartAccountProfileRecord {
        SmartAccountProfileRecord(
            id: id,
            accountId: accountId,
            implementationVersion: "barz_v1_0_0",
            ownerPublicKeyX: String(repeating: "11", count: 32),
            ownerPublicKeyY: String(repeating: "22", count: 32),
            curve: "secp256r1",
            salt: "0",
            createdAt: 1_700_000_000
        )
    }

    func makeGasFreeProfile(
        accountId: String = UUID().uuidString
    ) -> GasFreeProfileRecord {
        GasFreeProfileRecord(
            accountId: accountId,
            controllerAddress: "TGzz8gjYiYRqpfmDwnLxfgPuLVNmpCswVp",
            gasFreeAddress: "TXLAQ63Xg1NAzckPwKHvzw7CSEmLMEqcdj",
            providerId: "open.gasfree.io",
            verifyingContract: "TGXQF4Q6m9cQ4Qfq7gZQhQ7Jf7aS7m3nX4",
            implementationVersion: "gasfree_v1_0_0",
            createdAt: 1_700_000_000,
            lastVerifiedAt: 1_700_000_010
        )
    }

    func makeDeployment(
        id: String = UUID().uuidString,
        profileId: String,
        blockchainType: String = "ethereum",
        isDeployed: Bool = false
    ) -> SmartAccountDeploymentRecord {
        SmartAccountDeploymentRecord(
            id: id,
            profileId: profileId,
            blockchainType: blockchainType,
            implementationVersion: "barz_v1_0_0",
            isDeployed: isDeployed,
            preferredPaymaster: "pimlico",
            activatedAt: 1_700_000_000
        )
    }

    func makePendingOp(
        userOpHash: String = "0x" + UUID().uuidString.replacingOccurrences(of: "-", with: ""),
        deploymentId: String,
        status: String = "submitted"
    ) -> PendingUserOperationRecord {
        PendingUserOperationRecord(
            userOpHash: userOpHash,
            deploymentId: deploymentId,
            implementationVersion: "barz_v1_0_0",
            txHash: nil,
            status: status,
            submittedAt: 1_700_000_000,
            lastPolledAt: nil
        )
    }
}
