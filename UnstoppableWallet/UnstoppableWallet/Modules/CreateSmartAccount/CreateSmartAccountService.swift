import Foundation
import MarketKit

protocol SmartAccountPasskeyRegistering {
    func register(name: String) async throws -> SmartAccountPasskeyManager.Registration
}

extension SmartAccountPasskeyManager: SmartAccountPasskeyRegistering {}

class CreateSmartAccountService {
    private static let v1BlockchainTypes: [BlockchainType] = [.ethereum, .binanceSmartChain]

    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let smartAccountManager: SmartAccountManager
    private let activateDefaultWallets: (Account) -> Void
    private let passkeyRegistering: SmartAccountPasskeyRegistering

    init(
        accountFactory: AccountFactory,
        accountManager: AccountManager,
        smartAccountManager: SmartAccountManager,
        activateDefaultWallets: @escaping (Account) -> Void,
        passkeyRegistering: SmartAccountPasskeyRegistering = SmartAccountPasskeyManager()
    ) {
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.smartAccountManager = smartAccountManager
        self.activateDefaultWallets = activateDefaultWallets
        self.passkeyRegistering = passkeyRegistering
    }
}

extension CreateSmartAccountService {
    func create(name: String) async throws -> Account {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CreateError.emptyName }

        let registration = try await passkeyRegistering.register(name: trimmed)

        let account = accountFactory.account(
            type: .passkeyOwned(
                credentialID: registration.credentialID,
                publicKeyX: registration.publicKeyX,
                publicKeyY: registration.publicKeyY
            ),
            origin: .created,
            backedUp: true,
            fileBackedUp: false,
            name: trimmed
        )

        // Profile first (aa.sqlite). If anything below fails, startup repair removes orphan.
        let profile = try smartAccountManager.createProfile(account: account)

        for blockchainType in Self.v1BlockchainTypes {
            _ = try smartAccountManager.createDeployment(profile: profile, blockchainType: blockchainType)
        }

        // Account last (bank.sqlite).
        accountManager.save(account: account)

        // Best-effort wallet activation. Closure caller decides network/error handling;
        // no-op in tests. Any failure is invisible here — user lands in Balance empty,
        // can re-add tokens later.
        activateDefaultWallets(account)

        accountManager.set(lastCreatedAccount: account)

        stat(page: .newWalletPasskey, event: .createWallet(walletType: account.type.statDescription))

        return account
    }
}

extension CreateSmartAccountService {
    // Default production activation closure. Call-sites (Part 9 VM) use this with Core.shared deps.
    static func defaultActivator(
        marketKit: MarketKit.Kit,
        walletManager: WalletManager
    ) -> (Account) -> Void {
        { account in
            do {
                let tokens = try marketKit.tokens(queries: StablecoinRegistry.v1TokenQueries)
                let wallets = tokens.map { Wallet(token: $0, account: account) }
                walletManager.save(wallets: wallets)
            } catch {
                print("[CreateSmartAccountService] default wallet activation failed: \(error)")
            }
        }
    }
}

extension CreateSmartAccountService {
    enum CreateError: Error {
        case emptyName
    }
}
