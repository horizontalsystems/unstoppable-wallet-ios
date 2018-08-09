import Foundation

class InputSigner {
    enum SignError: Error {
        case noPreviousOutput
        case noPreviousOutputAddress
        case noPublicKeyHashInOutput
        case noPublicKeyInOutput
        case noPrivateKey
    }


    static let shared = InputSigner()

    let walletKitManager: WalletKitManager
    let realmFactory: RealmFactory
    let scriptBuilder: ScriptBuilder

    init(realmFactory: RealmFactory = .shared, walletKitManager: WalletKitManager = .shared, scriptBuilder: ScriptBuilder = .shared) {
        self.realmFactory = realmFactory
        self.walletKitManager = walletKitManager
        self.scriptBuilder = scriptBuilder
    }

    func signature(input: TransactionInput, transaction: Transaction, index: Int) throws -> Data {
        let realm = realmFactory.realm

        guard let prevOutput = input.previousOutput else {
            throw SignError.noPreviousOutput
        }

        guard let keyHash = prevOutput.keyHash else {
            throw SignError.noPublicKeyHashInOutput
        }

        guard let address = realm.objects(Address.self).filter("publicKeyHash = %@", keyHash).last else {
            throw SignError.noPreviousOutputAddress
        }

        guard let publicKey = address.publicKey else {
            throw SignError.noPublicKeyInOutput
        }

        guard let privateKey = try? walletKitManager.hdWallet.privateKey(index: address.index, chain: address.external ? .external : .internal) else {
            throw SignError.noPrivateKey
        }

        let signature = try Crypto.sign(data: transaction.serializedForSignature(inputIndex: index), privateKey: privateKey.raw)
        return scriptBuilder.unlockingScript(params: [signature, publicKey])
    }
}
