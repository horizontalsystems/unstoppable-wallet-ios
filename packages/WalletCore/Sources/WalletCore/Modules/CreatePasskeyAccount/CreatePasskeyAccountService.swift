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
    // Self-selects: returns the account type for `abstract` if this provisioner handles it, else nil
    // (chain passes to the next). Throws if it handles `abstract` but type construction fails.
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
    private let passkeyManager: PasskeyManager

    init(accountFactory: AccountFactory, accountManager: AccountManager, walletManager: WalletManager, passkeyManager: PasskeyManager = PasskeyManager()) {
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.passkeyManager = passkeyManager
    }
}

public extension CreatePasskeyAccountService {
    func create(name: String, abstract: AccountType.Abstract) async throws -> Account {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CreateError.emptyName }

        let registration = try await passkeyManager.register(name: trimmed)
        // The attestation carries the credential's public key and is the provisioning payload — without
        // it the account can't be provisioned. Fail here, before the next biometric prompt.
        guard let attestationObject = registration.attestationObject else {
            throw CreateError.missingAttestation
        }
        // The PRF assertion derives the wallet seed (PRF → mnemonic → seed).
        let passkey = try await passkeyManager.loginWith(credentialID: registration.credentialID)
        return try provision(
            abstract: abstract, credentialID: registration.credentialID, mnemonic: passkey.mnemonic,
            credentials: .create(attestation: attestationObject), origin: .created,
            name: trimmed, statPage: .newWalletPasskey
        ) { .createWallet(walletType: $0) }
    }

    func restore(abstract: AccountType.Abstract) async throws -> Account {
        let passkey = try await passkeyManager.login()
        // Restore must not fail on a missing/odd display name — the credential's userID is outside our
        // control. Fall back to a default; wallet identity comes from the credential, not the name.
        let trimmed = passkey.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Passkey Wallet" : trimmed

        // Restore reuses the provisioning path with `.restore`: the provisioner recovers the credential's
        // public key out-of-band (synchronizable keychain). `origin: .restored` keeps provenance correct.
        return try provision(
            abstract: abstract, credentialID: passkey.credentialID, mnemonic: passkey.mnemonic,
            credentials: .restore, origin: .restored,
            name: name, statPage: .importWalletPasskey
        ) { .importWallet(walletType: $0) }
    }

    private func provision(abstract: AccountType.Abstract, credentialID: Data, mnemonic: [String], credentials: ProvisioningCredentials, origin: AccountOrigin, name: String, statPage: StatPage, statEvent: (String) -> StatEvent) throws -> Account {
        for provisioner in Self.provisioners {
            guard let type = provisioner.accountType(abstract: abstract, credentialID: credentialID, mnemonic: mnemonic) else {
                continue
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

        throw CreateError.noProvisioner
    }
}

extension CreatePasskeyAccountService {
    enum CreateError: Error {
        case emptyName
        case noProvisioner
        case seedDerivationFailed
        case missingAttestation
    }
}
