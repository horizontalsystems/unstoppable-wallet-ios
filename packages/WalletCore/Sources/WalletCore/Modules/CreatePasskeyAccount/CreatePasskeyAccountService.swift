import Foundation
import HdWalletKit
import MarketKit

public protocol IAccountProvisioner {
    // Self-selects: returns the account type for `abstract` if this provisioner handles it, else nil
    // (chain passes to the next). Throws if it handles `abstract` but type construction fails.
    func accountType(abstract: AccountType.Abstract, credentialID: Data, mnemonic: [String]) -> AccountType?
    func provision(account: Account, seed: Data) throws -> [Token]
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

        let credentialID = try await passkeyManager.create(name: trimmed)
        let passkey = try await passkeyManager.loginWith(credentialID: credentialID)
        return try provision(abstract: abstract, credentialID: credentialID, mnemonic: passkey.mnemonic, name: trimmed, statPage: .newWalletPasskey) { .createWallet(walletType: $0) }
    }

    func restore(abstract: AccountType.Abstract) async throws -> Account {
        let passkey = try await passkeyManager.login()
        let trimmed = passkey.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CreateError.emptyName }

        return try provision(abstract: abstract, credentialID: passkey.credentialID, mnemonic: passkey.mnemonic, name: trimmed, statPage: .importWalletPasskey) { .importWallet(walletType: $0) }
    }

    private func provision(abstract: AccountType.Abstract, credentialID: Data, mnemonic: [String], name: String, statPage: StatPage, statEvent: (String) -> StatEvent) throws -> Account {
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
            let tokens = try provisioner.provision(account: account, seed: seed)

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
    }
}
