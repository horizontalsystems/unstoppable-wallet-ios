import Foundation
import HdWalletKit
import TonKit
import TonSwift
import TweetNacl

class TonKitManager {
    private weak var _tonKit: Kit?
    private var currentAccount: Account?

    private let queue = DispatchQueue(label: "\(AppConfig.label).ton-kit-manager", qos: .userInitiated)

    private func _tonKit(account: Account) throws -> Kit {
        if let _tonKit, let currentAccount, currentAccount == account {
            return _tonKit
        }

        let type: Kit.WalletType

        switch account.type {
        case .mnemonic:
            guard let seed = account.type.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }

            let hdWallet = HDWallet(seed: seed, coinType: 607, xPrivKey: 0, curve: .ed25519)
            let privateKey = try hdWallet.privateKey(account: 0)
            let privateRaw = Data(privateKey.raw.bytes)
            let pair = try TweetNacl.NaclSign.KeyPair.keyPair(fromSeed: privateRaw)
            let keyPair = KeyPair(publicKey: .init(data: pair.publicKey), privateKey: .init(data: pair.secretKey))

            type = .full(keyPair)
        case let .tonAddress(address):
            let tonAddress = try TonSwift.Address.parse(address)
            type = .watch(tonAddress)
        default:
            throw AdapterError.unsupportedAccount
        }

        let tonKit = try Kit.instance(
            type: type,
            walletVersion: .v4,
            network: .mainNet,
            walletId: account.id,
            minLogLevel: .error
        )

        tonKit.sync()
        tonKit.startListener()

        _tonKit = tonKit
        currentAccount = account

        return tonKit
    }
}

extension TonKitManager {
    var tonKit: Kit? {
        queue.sync { _tonKit }
    }

    func tonKit(account: Account) throws -> Kit {
        try queue.sync { try _tonKit(account: account) }
    }
}
