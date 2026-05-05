import EvmKit
import Foundation
import HdWalletKit
import HsCryptoKit
import MarketKit

/// Returned by SmartAccountPasskeyRegistering.register. Carries the new passkey's
/// credentialID together with the PRF-derived mnemonic that the service uses to
/// derive a secp256k1 EOA owner for the Barz Smart Account.
struct SmartAccountPasskeyRegistration: Equatable {
    let credentialID: Data
    let mnemonic: [String]
}

protocol SmartAccountPasskeyRegistering {
    func register(name: String) async throws -> SmartAccountPasskeyRegistration
}

extension PasskeyManager: SmartAccountPasskeyRegistering {
    func register(name: String) async throws -> SmartAccountPasskeyRegistration {
        let credentialID = try await create(name: name)
        let passkey = try await loginWith(credentialID: credentialID)
        return SmartAccountPasskeyRegistration(credentialID: credentialID, mnemonic: passkey.mnemonic)
    }
}

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
        passkeyRegistering: SmartAccountPasskeyRegistering = PasskeyManager()
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

        // Derive secp256k1 owner pubkey halves from the PRF-derived mnemonic via
        // BIP44 m/44'/60'/0'/0/0. PrivKey lives only in this scope; only the
        // public X and Y are persisted in account_abstraction_profiles.
        guard let seed = Mnemonic.seed(mnemonic: registration.mnemonic, passphrase: "") else {
            throw CreateError.seedDerivationFailed
        }
        let privateKey = try Signer.privateKey(seed: seed, chain: .ethereum)
        let pubkey = Crypto.publicKey(privateKey: privateKey, compressed: false)
        let publicKeyX = Data(pubkey.dropFirst().prefix(32))
        let publicKeyY = Data(pubkey.dropFirst().suffix(32))

        let account = accountFactory.account(
            type: .passkeyOwned(
                credentialID: registration.credentialID
            ),
            origin: .created,
            backedUp: true,
            fileBackedUp: false,
            name: trimmed
        )

        // Profile first (aa.sqlite). If anything below fails, startup repair removes orphan.
        let profile = try smartAccountManager.createProfile(
            account: account,
            ownerPublicKeyX: publicKeyX,
            ownerPublicKeyY: publicKeyY,
            curve: .secp256k1
        )

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
        case seedDerivationFailed
    }
}
