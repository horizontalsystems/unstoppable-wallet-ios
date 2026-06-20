import Foundation
import HdWalletKit
import MarketKit

public protocol IAccountProvisioner {
    // Self-selects: returns the account type for `abstract` if this provisioner handles it, else nil
    // (chain passes to the next). Throws if it handles `abstract` but type construction fails.
    func accountType(abstract: AccountType.Abstract, credentialID: Data, mnemonic: [String]) -> AccountType?
    // `attestation` is the raw passkey registration attestation (it carries the credential's public key);
    // supplied at create from the fresh registration, nil when the authenticator returned none.
    func provision(account: Account, seed: Data, attestation: Data?) throws -> [Token]
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
        // The attestation carries the credential's public key and is the provisioning payload — without it
        // the account can't be provisioned. Fail here, before the next biometric prompt.
        guard let attestationObject = registration.attestationObject else {
            throw CreateError.missingAttestation
        }
        // The PRF assertion derives the wallet seed (PRF → mnemonic → seed).
        let passkey = try await passkeyManager.loginWith(credentialID: registration.credentialID)
        return try provision(abstract: abstract, credentialID: registration.credentialID, mnemonic: passkey.mnemonic, attestation: attestationObject, name: trimmed, statPage: .newWalletPasskey) { .createWallet(walletType: $0) }
    }

    func restore(abstract _: AccountType.Abstract) async throws -> Account {
        // NOT IMPLEMENTED YET. Restore must recover the credential's public key (x,y) on a fresh device.
        // WebAuthn assertion does not return the public key, so the planned path is reading (x,y) from the
        // synchronized keychain keyed by credentialID. Until that lands, fail loudly rather than silently
        // produce a wrong/empty account.
        fatalError("Passkey restore is not implemented yet (pending keychain (x,y) recovery)")
    }

    private func provision(abstract: AccountType.Abstract, credentialID: Data, mnemonic: [String], attestation: Data?, name: String, statPage: StatPage, statEvent: (String) -> StatEvent) throws -> Account {
        for provisioner in Self.provisioners {
            guard let type = provisioner.accountType(abstract: abstract, credentialID: credentialID, mnemonic: mnemonic) else {
                continue
            }
            guard let seed = Mnemonic.seed(mnemonic: mnemonic, passphrase: "") else {
                throw CreateError.seedDerivationFailed
            }

            let account = accountFactory.account(type: type, origin: .created, backedUp: true, fileBackedUp: false, name: name)

            // Provisioner persists its records first; if it or the save below throws the account is never
            // saved, so the provisioner's records are orphaned (its own repair handles them).
            let tokens = try provisioner.provision(account: account, seed: seed, attestation: attestation)

            accountManager.save(account: account)
            walletManager.save(wallets: tokens.map { Wallet(token: $0, account: account) })
            accountManager.set(lastCreatedAccount: account)

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
