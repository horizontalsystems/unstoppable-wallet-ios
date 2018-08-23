import Foundation

class HDWallet {
    let network: NetworkProtocol

    private let seed: Data
    private let keychain: HDKeychain

    private let purpose: UInt32
    private let coinType: UInt32
    var account: UInt32

    init(seed: Data, network: NetworkProtocol) {
        self.seed = seed
        self.network = network

        keychain = HDKeychain(seed: seed, network: network)
        purpose = 44
        coinType = network.coinType
        account = 0
    }

    func publicKey(index: Int, external: Bool) throws -> PublicKey {
        return PublicKey(withIndex: index, external: external, hdPublicKey: try publicKey(index: index, chain: external ? .external : .internal))
    }

    func receivePublicKey(index: Int) throws -> PublicKey {
        return PublicKey(withIndex: index, external: true, hdPublicKey: try publicKey(index: index, chain: .external))
    }

    func changePublicKey(index: Int) throws -> PublicKey {
        return PublicKey(withIndex: index, external: false, hdPublicKey: try publicKey(index: index, chain: .internal))
    }

    func privateKey(index: Int, chain: Chain) throws -> HDPrivateKey {
        return try privateKey(path: "m/\(purpose)'/\(coinType)'/\(account)'/\(chain.rawValue)/\(index)")
    }

    func privateKey(path: String) throws -> HDPrivateKey {
        let privateKey = try keychain.derivedKey(path: path)
        return privateKey
    }

    func publicKey(index: Int, chain: Chain) throws -> HDPublicKey {
        return try privateKey(index: index, chain: chain).publicKey()
    }

    enum Chain : Int {
        case external
        case `internal`
    }

}
