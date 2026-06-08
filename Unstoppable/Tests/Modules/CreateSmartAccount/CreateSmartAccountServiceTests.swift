import EvmKit
import Foundation
import HdWalletKit
import HsCryptoKit
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

struct CreateSmartAccountServiceTests {
    @Test func createRejectsEmptyName() async throws {
        let env = try SmartAccountTestEnvironment()
        let service = try makeService(env: env)

        await #expect(throws: CreateSmartAccountService.CreateError.emptyName) {
            _ = try await service.create(name: "   ")
        }

        let accounts = env.accountManager.allAccounts
        let profiles = try env.smartAccountManager.profiles()
        #expect(accounts.isEmpty)
        #expect(profiles.isEmpty)
    }

    @Test func createTrimsName() async throws {
        let env = try SmartAccountTestEnvironment()
        let service = try makeService(env: env)

        let account = try await service.create(name: "  Alice  ")

        #expect(account.name == "Alice")
    }

    @Test func createRejectsPasskeyFailure() async throws {
        let env = try SmartAccountTestEnvironment()
        let failing = FakePasskeyProviding.failing(with: StubError.failed)
        let service = try makeService(env: env, passkey: failing)

        await #expect(throws: StubError.failed) {
            _ = try await service.create(name: "Alice")
        }

        #expect(env.accountManager.allAccounts.isEmpty)
        let profiles = try env.smartAccountManager.profiles()
        #expect(profiles.isEmpty)
    }

    @Test func createHappyPathPersistsCoreRecords() async throws {
        let env = try SmartAccountTestEnvironment()
        let service = try makeService(env: env)

        let account = try await service.create(name: "Alice")

        #expect(env.accountManager.allAccounts.count == 1)
        #expect(env.accountManager.allAccounts.first?.id == account.id)

        let profiles = try env.smartAccountManager.profiles()
        #expect(profiles.count == 1)
        let profile = try #require(profiles.first)

        let deployments = try env.smartAccountManager.deployments(profileId: profile.id)
        let deploymentChains = Set(deployments.map(\.blockchainType))
        #expect(deploymentChains == Set([.ethereum, .binanceSmartChain, .base]))

        let fetchedProfile = try env.smartAccountManager.gasFreeProfile(accountId: account.id)
        let gasFreeProfile = try #require(fetchedProfile)
        #expect(gasFreeProfile.implementationVersion == "gasfree_v1_0_0")
        #expect(gasFreeProfile.verifyingContract == GasFreeChainAddresses.mainnetFactory)
        #expect(gasFreeProfile.providerId == GasFreeChainAddresses.mainnetServiceProvider)
    }

    /// Account identity stores only credentialID. Mnemonic-derived owner pubkey
    /// is persisted in account_abstraction_profiles.
    @Test func createPersistsCredentialOnlyAccountType() async throws {
        let env = try SmartAccountTestEnvironment()
        let service = try makeService(env: env)

        let account = try await service.create(name: "Alice")

        guard case let .passkeyOwned(credentialID) = account.type else {
            Issue.record("expected .passkeyOwned, got \(account.type)")
            return
        }
        #expect(credentialID == Data(repeating: 0xCC, count: 16))
    }

    /// Profile's implementationVersion reflects the curve used at creation.
    @Test func createTagsProfileWithBarzV1EcdsaImplementationVersion() async throws {
        let env = try SmartAccountTestEnvironment()
        let service = try makeService(env: env)

        let account = try await service.create(name: "Alice")
        let optionalProfile = try env.smartAccountManager.profile(accountId: account.id)
        let profile = try #require(optionalProfile)

        #expect(profile.implementationVersion == "barz_v1_ecdsa")
        #expect(profile.curve == .secp256k1)
    }

    /// For the canonical hardhat test mnemonic at m/44'/60'/0'/0/0 the EOA owner
    /// is 0xf39Fd6e5...92266 (verified Q1). The service must derive the secp256k1
    /// pubkey halves consistently; profile.address is the BarzAddressResolver
    /// result for that EOA on Mainnet.
    @Test func createDerivesOwnerFromHardhatMnemonic() async throws {
        let env = try SmartAccountTestEnvironment()
        let mnemonic = [
            "test", "test", "test", "test", "test", "test",
            "test", "test", "test", "test", "test", "junk",
        ]
        let passkey = FakePasskeyProviding.returning(mnemonic: mnemonic)
        let service = try makeService(env: env, passkey: passkey)

        let account = try await service.create(name: "Alice")

        let seed = try #require(Mnemonic.seed(mnemonic: mnemonic, passphrase: ""))
        let privateKey = try Signer.privateKey(seed: seed, chain: .ethereum)
        let expectedEoa = try EvmKit.Address(hex: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
        #expect(Signer.address(privateKey: privateKey) == expectedEoa)

        let pubkey = Crypto.publicKey(privateKey: privateKey, compressed: false)
        let x = Data(pubkey.dropFirst().prefix(32))
        let y = Data(pubkey.dropFirst().suffix(32))

        let optionalProfile = try env.smartAccountManager.profile(accountId: account.id)
        let profile = try #require(optionalProfile)
        #expect(x == Data(pubkey.dropFirst().prefix(32)))
        #expect(y == Data(pubkey.dropFirst().suffix(32)))
        #expect(profile.ownerPublicKeyX == x)
        #expect(profile.ownerPublicKeyY == y)

        let expectedAddress = try BarzAddressResolver.resolveLocally(
            publicKeyX: x,
            publicKeyY: y,
            curve: .secp256k1,
            blockchainType: .ethereum
        )
        let actualAddress = try profile.address(blockchainType: .ethereum)
        #expect(actualAddress == expectedAddress)
    }

    @Test func createSetsLastCreatedAccount() async throws {
        let env = try SmartAccountTestEnvironment()
        let service = try makeService(env: env)

        let account = try await service.create(name: "Alice")

        #expect(env.accountManager.lastCreatedAccount?.id == account.id)
    }

    @Test func createInvokesWalletActivationClosure() async throws {
        let env = try SmartAccountTestEnvironment()
        let activatorCallCount = Box<Int>(0)
        let service = try makeService(env: env, activator: { _ in
            activatorCallCount.value += 1
        })

        _ = try await service.create(name: "Alice")

        #expect(activatorCallCount.value == 1)
    }

    // MARK: - Helpers

    private func makeService(
        env: SmartAccountTestEnvironment,
        passkey: SmartAccountPasskeyProviding? = nil,
        activator: @escaping (Account) -> Void = { _ in }
    ) throws -> CreateSmartAccountService {
        let accountFactory = AccountFactory(accountManager: env.accountManager)
        return CreateSmartAccountService(
            accountFactory: accountFactory,
            accountManager: env.accountManager,
            smartAccountManager: env.smartAccountManager,
            activateDefaultWallets: activator,
            passkeyProvider: passkey ?? FakePasskeyProviding.defaultOk
        )
    }
}

private struct FakePasskeyProviding: SmartAccountPasskeyProviding {
    let result: Result<SmartAccountPasskeyRegistration, Error>

    func register(name _: String) async throws -> SmartAccountPasskeyRegistration {
        try result.get()
    }

    func restore() async throws -> SmartAccountPasskeyRegistration {
        try result.get()
    }

    static var defaultOk: FakePasskeyProviding {
        // Hardhat test mnemonic — well-known fixture across the EVM tooling ecosystem.
        // Yields EOA 0xf39Fd6e5...92266 at m/44'/60'/0'/0/0.
        returning(mnemonic: [
            "test", "test", "test", "test", "test", "test",
            "test", "test", "test", "test", "test", "junk",
        ])
    }

    static func returning(mnemonic: [String]) -> FakePasskeyProviding {
        FakePasskeyProviding(result: .success(
            SmartAccountPasskeyRegistration(
                credentialID: Data(repeating: 0xCC, count: 16),
                mnemonic: mnemonic,
                name: "Alice"
            )
        ))
    }

    static func failing(with error: Error) -> FakePasskeyProviding {
        FakePasskeyProviding(result: .failure(error))
    }
}

private enum StubError: Error, Equatable {
    case failed
}

// Simple reference wrapper for mutable captures inside closures.
private final class Box<T> {
    var value: T
    init(_ value: T) { self.value = value }
}
