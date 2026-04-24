import EvmKit
import Foundation
import GRDB
import MarketKit
import Testing
@testable import Unstoppable

struct SmartAccountManagerTests {
    @Test func initCreatesAaSqliteAndRunsMigrations() throws {
        let env = try SmartAccountTestEnvironment()

        let aaUrl = env.tempDir.appendingPathComponent("aa.sqlite")
        #expect(FileManager.default.fileExists(atPath: aaUrl.path))

        // Migrations ran — profiles query works without throwing.
        let profiles = try env.smartAccountManager.profiles()
        #expect(profiles.isEmpty)
    }

    @Test func createProfileRejectsInvalidAccountType() throws {
        let env = try SmartAccountTestEnvironment()
        let nonPasskey = Account(
            id: UUID().uuidString,
            level: 0,
            name: "mnemonic",
            type: .mnemonic(words: ["abandon"], salt: "", bip39Compliant: true),
            origin: .created,
            backedUp: false,
            fileBackedUp: false
        )

        #expect(throws: SmartAccountManager.SmartAccountError.invalidAccountType) {
            _ = try env.smartAccountManager.createProfile(account: nonPasskey)
        }
    }

    @Test func createProfileComputesCorrectAddress() throws {
        let env = try SmartAccountTestEnvironment()
        let account = env.makePasskeyAccount(
            publicKeyX: Data(repeating: 0x11, count: 32),
            publicKeyY: Data(repeating: 0x22, count: 32)
        )

        let profile = try env.smartAccountManager.createProfile(account: account)

        let expected = try EvmKit.Address(hex: "0x9eab247c9c7406b1bb38a972730ce18c40046d30")
        #expect(profile.address == expected)
        #expect(profile.implementationVersion == "barz_v1_0_0")
        #expect(profile.ownerPublicKeyX == Data(repeating: 0x11, count: 32))
        #expect(profile.ownerPublicKeyY == Data(repeating: 0x22, count: 32))
    }

    @Test func createProfileIsIdempotentForSameAccount() throws {
        let env = try SmartAccountTestEnvironment()
        let account = env.makePasskeyAccount()

        let first = try env.smartAccountManager.createProfile(account: account)
        let second = try env.smartAccountManager.createProfile(account: account)

        #expect(first.id == second.id)
        let all = try env.smartAccountManager.profiles()
        #expect(all.count == 1)
    }

    @Test func createProfileDetectsPubkeyMismatch() throws {
        let env = try SmartAccountTestEnvironment()
        let accountId = UUID().uuidString
        let first = env.makePasskeyAccount(
            id: accountId,
            publicKeyX: Data(repeating: 0x11, count: 32),
            publicKeyY: Data(repeating: 0x22, count: 32)
        )
        let collided = env.makePasskeyAccount(
            id: accountId,
            publicKeyX: Data(repeating: 0xAA, count: 32),
            publicKeyY: Data(repeating: 0xBB, count: 32)
        )

        _ = try env.smartAccountManager.createProfile(account: first)

        #expect(throws: SmartAccountManager.SmartAccountError.pubkeyMismatch) {
            _ = try env.smartAccountManager.createProfile(account: collided)
        }
    }

    @Test func createDeploymentIsIdempotent() throws {
        let env = try SmartAccountTestEnvironment()
        let profile = try env.smartAccountManager.createProfile(account: env.makePasskeyAccount())

        let first = try env.smartAccountManager.createDeployment(profile: profile, blockchainType: .ethereum)
        let second = try env.smartAccountManager.createDeployment(profile: profile, blockchainType: .ethereum)

        #expect(first.id == second.id)
        let deployments = try env.smartAccountManager.deployments(profileId: profile.id)
        #expect(deployments.count == 1)
    }

    @Test func queryMethodsReturnDomainTypes() throws {
        let env = try SmartAccountTestEnvironment()
        let account = env.makePasskeyAccount()
        let profile = try env.smartAccountManager.createProfile(account: account)
        _ = try env.smartAccountManager.createDeployment(profile: profile, blockchainType: .ethereum)
        _ = try env.smartAccountManager.createDeployment(profile: profile, blockchainType: .binanceSmartChain)

        let byId = try env.smartAccountManager.profile(id: profile.id)
        let byAccount = try env.smartAccountManager.profile(accountId: account.id)
        let allProfiles = try env.smartAccountManager.profiles()
        let deployments = try env.smartAccountManager.deployments(profileId: profile.id)

        #expect(byId?.id == profile.id)
        #expect(byAccount?.id == profile.id)
        #expect(allProfiles.count == 1)
        #expect(deployments.count == 2)
        #expect(Set(deployments.map(\.blockchainType)) == Set([.ethereum, .binanceSmartChain]))
    }

    @Test func updateDeployedFlipsFlag() throws {
        let env = try SmartAccountTestEnvironment()
        let profile = try env.smartAccountManager.createProfile(account: env.makePasskeyAccount())
        let deployment = try env.smartAccountManager.createDeployment(profile: profile, blockchainType: .ethereum)
        #expect(deployment.isDeployed == false)

        try env.smartAccountManager.updateDeployed(deployment: deployment, isDeployed: true)

        let refreshed = try env.smartAccountManager.deployment(profileId: profile.id, blockchainType: .ethereum)
        #expect(refreshed?.isDeployed == true)
    }

    @Test func accountDeletedCascadesProfileAndDeployments() throws {
        let env = try SmartAccountTestEnvironment()
        let account = env.makePasskeyAccount()
        env.accountManager.save(account: account) // persist в bank.sqlite

        let profile = try env.smartAccountManager.createProfile(account: account)
        _ = try env.smartAccountManager.createDeployment(profile: profile, blockchainType: .ethereum)
        _ = try env.smartAccountManager.createDeployment(profile: profile, blockchainType: .binanceSmartChain)

        env.accountManager.delete(account: account)

        let remainingProfile = try env.smartAccountManager.profile(accountId: account.id)
        let remainingDeployments = try env.smartAccountManager.deployments(profileId: profile.id)

        #expect(remainingProfile == nil)
        #expect(remainingDeployments.isEmpty)
    }

    @Test func startupOrphanRepairRemovesProfileWithoutAccount() throws {
        let env = try SmartAccountTestEnvironment()
        let orphanAccount = env.makePasskeyAccount() // NOT saved into accountManager
        let profile = try env.smartAccountManager.createProfile(account: orphanAccount)
        let preRepair = try env.smartAccountManager.profile(id: profile.id)
        #expect(preRepair != nil)

        // Construct a second manager on the same aa.sqlite — its init runs orphan repair.
        let repaired = try SmartAccountManager(
            accountManager: env.accountManager,
            databaseDirectoryUrl: env.tempDir
        )
        let remaining = try repaired.profile(id: profile.id)

        #expect(remaining == nil)
    }

    @Test func clearAllEmptiesEverything() throws {
        let env = try SmartAccountTestEnvironment()
        let account = env.makePasskeyAccount()
        env.accountManager.save(account: account)
        let profile = try env.smartAccountManager.createProfile(account: account)
        _ = try env.smartAccountManager.createDeployment(profile: profile, blockchainType: .ethereum)
        _ = try env.smartAccountManager.createDeployment(profile: profile, blockchainType: .binanceSmartChain)

        try env.smartAccountManager.clearAll()

        let profiles = try env.smartAccountManager.profiles()
        let deployments = try env.smartAccountManager.deployments(profileId: profile.id)
        #expect(profiles.isEmpty)
        #expect(deployments.isEmpty)
    }
}
