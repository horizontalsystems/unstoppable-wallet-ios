import EvmKit
import Foundation
import HdWalletKit
import HsCryptoKit
import MarketKit
import TronKit
import WalletCore

/// Carries a passkey's credentialID together with the PRF-derived mnemonic that the
/// service uses to derive a secp256k1 EOA owner for the Barz Smart Account.
/// Produced both by registration (new passkey) and assertion (existing passkey).
struct SmartAccountPasskeyRegistration: Equatable {
    let credentialID: Data
    let mnemonic: [String]
    let name: String
}

protocol SmartAccountPasskeyProviding {
    func register(name: String) async throws -> SmartAccountPasskeyRegistration
    func restore() async throws -> SmartAccountPasskeyRegistration
}

extension PasskeyManager: SmartAccountPasskeyProviding {
    func register(name: String) async throws -> SmartAccountPasskeyRegistration {
        let credentialID = try await create(name: name)
        let passkey = try await loginWith(credentialID: credentialID)
        return SmartAccountPasskeyRegistration(credentialID: credentialID, mnemonic: passkey.mnemonic, name: name)
    }

    func restore() async throws -> SmartAccountPasskeyRegistration {
        let passkey = try await login()
        return SmartAccountPasskeyRegistration(credentialID: passkey.credentialID, mnemonic: passkey.mnemonic, name: passkey.name)
    }
}

class CreateSmartAccountService {
    private static let v1BlockchainTypes: [BlockchainType] = [.ethereum, .binanceSmartChain, .base]

    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let smartAccountManager: SmartAccountManager
    private let activateDefaultWallets: (Account) -> Void
    private let passkeyProvider: SmartAccountPasskeyProviding

    init(
        accountFactory: AccountFactory,
        accountManager: AccountManager,
        smartAccountManager: SmartAccountManager,
        activateDefaultWallets: @escaping (Account) -> Void,
        passkeyProvider: SmartAccountPasskeyProviding = PasskeyManager()
    ) {
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.smartAccountManager = smartAccountManager
        self.activateDefaultWallets = activateDefaultWallets
        self.passkeyProvider = passkeyProvider
    }
}

extension CreateSmartAccountService {
    func create(name: String) async throws -> Account {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CreateError.emptyName }

        let registration = try await passkeyProvider.register(name: trimmed)
        return try provision(registration: registration, name: trimmed, statPage: .newWalletPasskey) { .createWallet(walletType: $0) }
    }

    func restore() async throws -> Account {
        let registration = try await passkeyProvider.restore()
        let trimmed = registration.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CreateError.emptyName }

        return try provision(registration: registration, name: trimmed, statPage: .importWalletPasskey) { .importWallet(walletType: $0) }
    }

    private func provision(
        registration: SmartAccountPasskeyRegistration,
        name: String,
        statPage: StatPage,
        statEvent: (String) -> StatEvent
    ) throws -> Account {
        guard let seed = Mnemonic.seed(mnemonic: registration.mnemonic, passphrase: "") else {
            throw CreateError.seedDerivationFailed
        }

        let account = accountFactory.account(
            type: .passkeyOwned(
                credentialID: registration.credentialID
            ),
            origin: .created,
            backedUp: true,
            fileBackedUp: false,
            name: name
        )

        // aa.sqlite first. If anything below fails, startup repair removes orphan.
        try createAccountAbstractionProfiles(seed: seed, account: account)
        try createGasFreeProfile(seed: seed, account: account)

        // Account last (bank.sqlite).
        accountManager.save(account: account)

        // Best-effort wallet activation. Closure caller decides network/error handling;
        // no-op in tests. Any failure is invisible here — user lands in Balance empty,
        // can re-add tokens later.
        activateDefaultWallets(account)

        accountManager.set(lastCreatedAccount: account)

        stat(page: statPage, event: statEvent(account.type.statDescription))

        return account
    }

    /// Derives the EVM owner key via canonical EVM BIP44 m/44'/60'/0'/0/0 and persists
    /// the AA profile + per-chain deployment records. PrivKey lives only in this scope;
    /// only the public X/Y halves are stored in account_abstraction_profiles.
    private func createAccountAbstractionProfiles(seed: Data, account: Account) throws {
        let evmPrivateKey = try Signer.privateKey(seed: seed, chain: .ethereum)
        let pubkey = Crypto.publicKey(privateKey: evmPrivateKey, compressed: false)
        let publicKeyX = Data(pubkey.dropFirst().prefix(32))
        let publicKeyY = Data(pubkey.dropFirst().suffix(32))

        let profile = try smartAccountManager.createProfile(
            account: account,
            ownerPublicKeyX: publicKeyX,
            ownerPublicKeyY: publicKeyY,
            curve: .secp256k1
        )

        for blockchainType in Self.v1BlockchainTypes {
            _ = try smartAccountManager.createDeployment(profile: profile, blockchainType: blockchainType)
        }
    }

    /// Derives the Tron controller key via canonical Tron BIP44 m/44'/195'/0'/0/0 and
    /// persists the GasFree profile in aa.sqlite. No on-chain deployment yet — the
    /// BeaconProxy is created lazily on first GasFree submitTransfer.
    private func createGasFreeProfile(seed: Data, account: Account) throws {
        let tronPrivateKey = try TronKit.Signer.privateKey(seed: seed)
        let controllerAddress = try TronKit.Signer.address(privateKey: tronPrivateKey)

        _ = try smartAccountManager.createGasFreeProfile(account: account, controllerAddress: controllerAddress)
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
