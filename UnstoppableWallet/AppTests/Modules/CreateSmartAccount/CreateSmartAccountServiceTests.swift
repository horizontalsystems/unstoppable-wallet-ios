import EvmKit
import Foundation
import MarketKit
import Testing
@testable import Unstoppable

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
        let failing = FakePasskeyRegistering.failing(with: StubError.failed)
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
        #expect(deploymentChains == Set([.ethereum, .binanceSmartChain]))
    }

    @Test func createProducesStableAaAddress() async throws {
        let env = try SmartAccountTestEnvironment()
        let passkey = FakePasskeyRegistering.returning(
            publicKeyX: Data(repeating: 0x11, count: 32),
            publicKeyY: Data(repeating: 0x22, count: 32)
        )
        let service = try makeService(env: env, passkey: passkey)

        let account = try await service.create(name: "Alice")

        let lookup = try env.smartAccountManager.profile(accountId: account.id)
        let profile = try #require(lookup)
        let expected = try EvmKit.Address(hex: "0x9eab247c9c7406b1bb38a972730ce18c40046d30")
        #expect(profile.address == expected)
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
        passkey: SmartAccountPasskeyRegistering? = nil,
        activator: @escaping (Account) -> Void = { _ in }
    ) throws -> CreateSmartAccountService {
        let accountFactory = AccountFactory(accountManager: env.accountManager)
        return CreateSmartAccountService(
            accountFactory: accountFactory,
            accountManager: env.accountManager,
            smartAccountManager: env.smartAccountManager,
            activateDefaultWallets: activator,
            passkeyRegistering: passkey ?? FakePasskeyRegistering.defaultOk
        )
    }
}

private struct FakePasskeyRegistering: SmartAccountPasskeyRegistering {
    let result: Result<SmartAccountPasskeyManager.Registration, Error>

    func register(name _: String) async throws -> SmartAccountPasskeyManager.Registration {
        try result.get()
    }

    static var defaultOk: FakePasskeyRegistering {
        returning(
            publicKeyX: Data(repeating: 0x11, count: 32),
            publicKeyY: Data(repeating: 0x22, count: 32)
        )
    }

    static func returning(publicKeyX: Data, publicKeyY: Data) -> FakePasskeyRegistering {
        FakePasskeyRegistering(result: .success(
            SmartAccountPasskeyManager.Registration(
                credentialID: Data(repeating: 0xCC, count: 16),
                publicKeyX: publicKeyX,
                publicKeyY: publicKeyY
            )
        ))
    }

    static func failing(with error: Error) -> FakePasskeyRegistering {
        FakePasskeyRegistering(result: .failure(error))
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
