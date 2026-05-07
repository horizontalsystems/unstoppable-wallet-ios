import Foundation
import GRDB
import Testing
@testable import Unstoppable

struct SmartAccountDeploymentRecordStorageTests {
    @Test func saveRoundTrip() throws {
        let env = try AaStorageTestEnvironment()
        let profile = env.makeProfile()
        try env.profileStorage.save(record: profile)

        let original = env.makeDeployment(profileId: profile.id, blockchainType: "ethereum", isDeployed: false)
        try env.deploymentStorage.save(record: original)

        let fetched = try env.deploymentStorage.deployment(profileId: profile.id, blockchainType: "ethereum")
        let restored = try #require(fetched)

        #expect(restored.id == original.id)
        #expect(restored.blockchainType == original.blockchainType)
        #expect(restored.implementationVersion == original.implementationVersion)
        #expect(restored.isDeployed == original.isDeployed)
        #expect(restored.preferredPaymaster == original.preferredPaymaster)
        #expect(restored.activatedAt == original.activatedAt)
    }

    @Test func deploymentsByProfileId() throws {
        let env = try AaStorageTestEnvironment()
        let profileA = env.makeProfile()
        let profileB = env.makeProfile()
        try env.profileStorage.save(record: profileA)
        try env.profileStorage.save(record: profileB)

        try env.deploymentStorage.save(record: env.makeDeployment(profileId: profileA.id, blockchainType: "ethereum"))
        try env.deploymentStorage.save(record: env.makeDeployment(profileId: profileA.id, blockchainType: "binance-smart-chain"))
        try env.deploymentStorage.save(record: env.makeDeployment(profileId: profileB.id, blockchainType: "ethereum"))

        let deploymentsA = try env.deploymentStorage.deployments(profileId: profileA.id)
        let deploymentsB = try env.deploymentStorage.deployments(profileId: profileB.id)

        #expect(deploymentsA.count == 2)
        #expect(deploymentsB.count == 1)
    }

    @Test func updateDeployedFlipsFlag() throws {
        let env = try AaStorageTestEnvironment()
        let profile = env.makeProfile()
        try env.profileStorage.save(record: profile)

        let deployment = env.makeDeployment(profileId: profile.id, isDeployed: false)
        try env.deploymentStorage.save(record: deployment)

        try env.deploymentStorage.updateDeployed(id: deployment.id, isDeployed: true)

        let fetched = try env.deploymentStorage.deployment(profileId: profile.id, blockchainType: "ethereum")
        let restored = try #require(fetched)

        #expect(restored.isDeployed == true)
    }

    @Test func uniqueProfileChainPairThrows() throws {
        let env = try AaStorageTestEnvironment()
        let profile = env.makeProfile()
        try env.profileStorage.save(record: profile)

        let first = env.makeDeployment(profileId: profile.id, blockchainType: "ethereum")
        let second = env.makeDeployment(profileId: profile.id, blockchainType: "ethereum")
        try env.deploymentStorage.save(record: first)

        #expect(throws: (any Error).self) {
            try env.deploymentStorage.save(record: second)
        }
    }

    @Test func cascadeDeleteOnProfileRemoval() throws {
        let env = try AaStorageTestEnvironment()
        let profile = env.makeProfile()
        try env.profileStorage.save(record: profile)
        try env.deploymentStorage.save(record: env.makeDeployment(profileId: profile.id, blockchainType: "ethereum"))
        try env.deploymentStorage.save(record: env.makeDeployment(profileId: profile.id, blockchainType: "binance-smart-chain"))

        try env.profileStorage.delete(id: profile.id)

        let remaining = try env.deploymentStorage.deployments(profileId: profile.id)

        #expect(remaining.isEmpty)
    }

    @Test func deleteAllForProfile() throws {
        let env = try AaStorageTestEnvironment()
        let profile = env.makeProfile()
        try env.profileStorage.save(record: profile)
        try env.deploymentStorage.save(record: env.makeDeployment(profileId: profile.id, blockchainType: "ethereum"))
        try env.deploymentStorage.save(record: env.makeDeployment(profileId: profile.id, blockchainType: "binance-smart-chain"))

        try env.deploymentStorage.deleteAll(profileId: profile.id)

        let remaining = try env.deploymentStorage.deployments(profileId: profile.id)

        #expect(remaining.isEmpty)
    }

    @Test func clearRemovesAll() throws {
        let env = try AaStorageTestEnvironment()
        let profile = env.makeProfile()
        try env.profileStorage.save(record: profile)
        try env.deploymentStorage.save(record: env.makeDeployment(profileId: profile.id))

        try env.deploymentStorage.clear()

        let remaining = try env.deploymentStorage.all()

        #expect(remaining.isEmpty)
    }
}
