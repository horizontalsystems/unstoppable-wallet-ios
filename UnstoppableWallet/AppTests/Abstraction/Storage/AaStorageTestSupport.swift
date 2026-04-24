import Foundation
import GRDB
@testable import Unstoppable

struct AaStorageTestEnvironment {
    let dbPool: DatabasePool
    let profileStorage: SmartAccountProfileRecordStorage
    let deploymentStorage: SmartAccountDeploymentRecordStorage
    let pendingOpStorage: PendingUserOperationRecordStorage

    init() throws {
        let dbURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("aa-tests-\(UUID().uuidString).sqlite")
        let pool = try DatabasePool(path: dbURL.path)
        try AaStorageMigrator.migrate(dbPool: pool)

        dbPool = pool
        profileStorage = SmartAccountProfileRecordStorage(dbPool: pool)
        deploymentStorage = SmartAccountDeploymentRecordStorage(dbPool: pool)
        pendingOpStorage = PendingUserOperationRecordStorage(dbPool: pool)
    }

    func makeProfile(
        id: String = UUID().uuidString,
        accountId: String = UUID().uuidString
    ) -> SmartAccountProfileRecord {
        SmartAccountProfileRecord(
            id: id,
            accountId: accountId,
            address: "0x9eab247c9c7406b1bb38a972730ce18c40046d30",
            implementationVersion: "barz_v1_0_0",
            verificationFacet: "0xee1af8e967ec04c84711842796a5e714d2fd33e6",
            factoryAddress: "0x729c310186a57833f622630a16d13f710b83272a",
            entryPoint: "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789",
            ownerPublicKeyX: String(repeating: "11", count: 32),
            ownerPublicKeyY: String(repeating: "22", count: 32),
            salt: "0",
            createdAt: 1_700_000_000
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
            lastPolledAt: nil,
            bundlerUrl: "https://api.pimlico.io/v1/1/rpc?apikey=test"
        )
    }
}
