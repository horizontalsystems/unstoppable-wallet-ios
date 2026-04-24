import Foundation
import GRDB
import Testing
@testable import Unstoppable

struct PendingUserOperationRecordStorageTests {
    @Test func saveRoundTrip() throws {
        let env = try makeEnvWithDeployment()
        let original = env.env.makePendingOp(deploymentId: env.deploymentId, status: "submitted")

        try env.env.pendingOpStorage.save(record: original)

        let fetched = try env.env.pendingOpStorage.operation(userOpHash: original.userOpHash)
        let restored = try #require(fetched)

        #expect(restored.userOpHash == original.userOpHash)
        #expect(restored.deploymentId == original.deploymentId)
        #expect(restored.implementationVersion == original.implementationVersion)
        #expect(restored.txHash == original.txHash)
        #expect(restored.status == original.status)
        #expect(restored.submittedAt == original.submittedAt)
        #expect(restored.lastPolledAt == original.lastPolledAt)
        #expect(restored.bundlerUrl == original.bundlerUrl)
    }

    @Test func pendingByStatusFilter() throws {
        let env = try makeEnvWithDeployment()

        try env.env.pendingOpStorage.save(record: env.env.makePendingOp(deploymentId: env.deploymentId, status: "submitted"))
        try env.env.pendingOpStorage.save(record: env.env.makePendingOp(deploymentId: env.deploymentId, status: "submitted"))
        try env.env.pendingOpStorage.save(record: env.env.makePendingOp(deploymentId: env.deploymentId, status: "included"))

        let submitted = try env.env.pendingOpStorage.pendingOperations(status: "submitted")
        let included = try env.env.pendingOpStorage.pendingOperations(status: "included")
        let failed = try env.env.pendingOpStorage.pendingOperations(status: "failed")

        #expect(submitted.count == 2)
        #expect(included.count == 1)
        #expect(failed.isEmpty)
    }

    @Test func updateTransitionsSubmittedToIncluded() throws {
        let env = try makeEnvWithDeployment()
        let op = env.env.makePendingOp(deploymentId: env.deploymentId, status: "submitted")
        try env.env.pendingOpStorage.save(record: op)

        try env.env.pendingOpStorage.update(
            userOpHash: op.userOpHash,
            status: "included",
            txHash: "0xdeadbeef",
            lastPolledAt: 1_700_000_100
        )

        let fetched = try env.env.pendingOpStorage.operation(userOpHash: op.userOpHash)
        let updated = try #require(fetched)

        #expect(updated.status == "included")
        #expect(updated.txHash == "0xdeadbeef")
        #expect(updated.lastPolledAt == 1_700_000_100)
    }

    @Test func cascadeDeleteOnDeploymentRemoval() throws {
        let env = try makeEnvWithDeployment()
        try env.env.pendingOpStorage.save(record: env.env.makePendingOp(deploymentId: env.deploymentId))
        try env.env.pendingOpStorage.save(record: env.env.makePendingOp(deploymentId: env.deploymentId))

        try env.env.deploymentStorage.delete(id: env.deploymentId)

        let remaining = try env.env.pendingOpStorage.all()

        #expect(remaining.isEmpty)
    }

    @Test func cascadeDeleteOnProfileRemoval() throws {
        let env = try makeEnvWithDeployment()
        try env.env.pendingOpStorage.save(record: env.env.makePendingOp(deploymentId: env.deploymentId))

        try env.env.profileStorage.delete(id: env.profileId)

        let remaining = try env.env.pendingOpStorage.all()

        #expect(remaining.isEmpty)
    }

    @Test func deleteByHash() throws {
        let env = try makeEnvWithDeployment()
        let op = env.env.makePendingOp(deploymentId: env.deploymentId)
        try env.env.pendingOpStorage.save(record: op)

        try env.env.pendingOpStorage.delete(userOpHash: op.userOpHash)

        let fetched = try env.env.pendingOpStorage.operation(userOpHash: op.userOpHash)

        #expect(fetched == nil)
    }

    @Test func clearRemovesAll() throws {
        let env = try makeEnvWithDeployment()
        try env.env.pendingOpStorage.save(record: env.env.makePendingOp(deploymentId: env.deploymentId))
        try env.env.pendingOpStorage.save(record: env.env.makePendingOp(deploymentId: env.deploymentId))

        try env.env.pendingOpStorage.clear()

        let remaining = try env.env.pendingOpStorage.all()

        #expect(remaining.isEmpty)
    }

    // MARK: - Helpers

    private func makeEnvWithDeployment() throws -> (env: AaStorageTestEnvironment, profileId: String, deploymentId: String) {
        let env = try AaStorageTestEnvironment()
        let profile = env.makeProfile()
        try env.profileStorage.save(record: profile)
        let deployment = env.makeDeployment(profileId: profile.id)
        try env.deploymentStorage.save(record: deployment)
        return (env, profile.id, deployment.id)
    }
}
