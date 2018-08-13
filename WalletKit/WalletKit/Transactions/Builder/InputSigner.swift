import Foundation

class InputSigner {
    enum SignError: Error {
        case noPreviousOutput
        case noPreviousOutputAddress
        case noPublicKeyHashInOutput
        case noPublicKeyInAddress
        case noPrivateKey
    }

    let hdWallet: HDWallet
    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory, hdWallet: HDWallet) {
        self.realmFactory = realmFactory
        self.hdWallet = hdWallet
    }

    func sigScriptData(transaction: Transaction, index: Int) throws -> [Data] {
        let input = transaction.inputs[index]
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
            throw SignError.noPublicKeyInAddress
        }

        guard let privateKey = try? hdWallet.privateKey(index: address.index, chain: address.external ? .external : .internal) else {
            throw SignError.noPrivateKey
        }

        let serializedTransaction = try transaction.serializedForSignature(inputIndex: index) + UInt32(1)
        let signatureHash = Crypto.sha256sha256(serializedTransaction)
        let signature = try Crypto.sign(data: signatureHash, privateKey: privateKey.raw) + Data(bytes: [0x01])

        return [signature, publicKey]
    }

}
