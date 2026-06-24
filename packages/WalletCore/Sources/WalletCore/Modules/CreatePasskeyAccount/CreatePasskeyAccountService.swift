import Foundation
import HdWalletKit
import MarketKit

// Credential material handed to a provisioner: a fresh registration's attestation (which carries the
// credential's public key) on create, or nothing on restore (the provisioner recovers the public key
// out-of-band). Neutral WebAuthn/account-creation type — no AA specifics.
public enum ProvisioningCredentials {
    case create(attestation: Data)
    case restore
}

public protocol IAccountProvisioner {
    // The relying-party domain this provisioner's passkeys are bound to. The orchestrator builds the
    // WebAuthn ceremony with it, so each app's domain reaches the ceremony without WalletCore having to
    // read app-specific config.
    var domain: String { get }
    // Self-selection by abstract type, evaluated BEFORE the ceremony (no credential exists yet).
    func handles(abstract: AccountType.Abstract) -> Bool
    // Builds the account type from the credential the ceremony produced. nil only if construction fails.
    func accountType(abstract: AccountType.Abstract, credentialID: Data, mnemonic: [String]) -> AccountType?
    func provision(account: Account, seed: Data, credentials: ProvisioningCredentials) throws -> [Token]
}

public class CreatePasskeyAccountService {
    private static var provisioners: [IAccountProvisioner] = []

    public static func register(_ provisioner: IAccountProvisioner) {
        provisioners.insert(provisioner, at: 0)
    }

    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let walletManager: WalletManager

    // No PasskeyManager held here: the ceremony is built per request with the selected provisioner's
    // domain (the provisioner is the only thing that knows which relying-party domain to use).
    init(accountFactory: AccountFactory, accountManager: AccountManager, walletManager: WalletManager) {
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
    }
}

public extension CreatePasskeyAccountService {
    func create(name: String, abstract: AccountType.Abstract) async throws -> Account {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CreateError.emptyName }

        // Select the provisioner first — it carries the relying-party domain the ceremony must use.
        let provisioner = try Self.provisioner(for: abstract)
        let ceremony = PasskeyManager(domain: provisioner.domain)

        // One ceremony yields both the attestation (credential public key) and the wallet mnemonic.
        let registration = try await ceremony.registerWithPRF(name: trimmed)
        // The attestation carries the public key and is the provisioning payload — without it the account
        // can't be provisioned.
        guard let attestationObject = registration.attestationObject else {
            throw CreateError.missingAttestation
        }
        return try finalize(
            provisioner: provisioner, abstract: abstract,
            credentialID: registration.credentialID, mnemonic: registration.mnemonic,
            credentials: .create(attestation: attestationObject), origin: .created,
            name: trimmed, statPage: .newWalletPasskey
        ) { .createWallet(walletType: $0) }
    }

    func restore(abstract: AccountType.Abstract) async throws -> Account {
        let provisioner = try Self.provisioner(for: abstract)
        let ceremony = PasskeyManager(domain: provisioner.domain)

        let passkey = try await ceremony.login()
        // Restore must not fail on a missing/odd display name — the credential's userID is outside our
        // control. Fall back to a default; wallet identity comes from the credential, not the name.
        let trimmed = passkey.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Passkey Wallet" : trimmed

        // Restore reuses the provisioning path with `.restore`: the provisioner recovers the credential's
        // public key out-of-band (synchronizable keychain). `origin: .restored` keeps provenance correct.
        return try finalize(
            provisioner: provisioner, abstract: abstract,
            credentialID: passkey.credentialID, mnemonic: passkey.mnemonic,
            credentials: .restore, origin: .restored,
            name: name, statPage: .importWalletPasskey
        ) { .importWallet(walletType: $0) }
    }

    private func finalize(provisioner: IAccountProvisioner, abstract: AccountType.Abstract, credentialID: Data, mnemonic: [String], credentials: ProvisioningCredentials, origin: AccountOrigin, name: String, statPage: StatPage, statEvent: (String) -> StatEvent) throws -> Account {
        guard let type = provisioner.accountType(abstract: abstract, credentialID: credentialID, mnemonic: mnemonic) else {
            throw CreateError.noProvisioner
        }
        guard let seed = Mnemonic.seed(mnemonic: mnemonic, passphrase: "") else {
            throw CreateError.seedDerivationFailed
        }

        let account = accountFactory.account(type: type, origin: origin, backedUp: true, fileBackedUp: false, name: name)

        // Provisioner persists its records first; if it or the save below throws the account is never
        // saved, so the provisioner's records are orphaned (its own repair handles them).
        let tokens = try provisioner.provision(account: account, seed: seed, credentials: credentials)

        accountManager.save(account: account)
        walletManager.save(wallets: tokens.map { Wallet(token: $0, account: account) })
        // `lastCreatedAccount` is a create-only signal (popped once on Main) — a restored account must
        // not be marked as the "last created" one.
        if origin == .created {
            accountManager.set(lastCreatedAccount: account)
        }

        stat(page: statPage, event: statEvent(account.type.statDescription))

        return account
    }
}

extension CreatePasskeyAccountService {
    // First registered provisioner that handles `abstract` (selection before any ceremony).
    static func provisioner(for abstract: AccountType.Abstract) throws -> IAccountProvisioner {
        guard let provisioner = provisioners.first(where: { $0.handles(abstract: abstract) }) else {
            throw CreateError.noProvisioner
        }
        return provisioner
    }

    enum CreateError: Error {
        case emptyName
        case noProvisioner
        case seedDerivationFailed
        case missingAttestation
    }
}
