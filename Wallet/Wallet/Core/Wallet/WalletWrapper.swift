import Foundation
import BitcoinKit

class WalletWrapper {
    private let hdWallet: HDWallet

    init(words: [String]) {
        let seed = Mnemonic.seed(mnemonic: words, passphrase: "")

        hdWallet = HDWallet(seed: seed, network: Network.testnet)
    }

    var identity: String {
        let publicKey = try! hdWallet.publicKey()
        return Base58.encode(Crypto.sha256(publicKey.raw))
    }

    var pubKeys: [Int: String] {
        return [:]
    }

}
