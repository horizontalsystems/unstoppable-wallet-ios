import BitcoinCore
import Foundation
import HdWalletKit
import LitecoinKit
import MarketKit
import RxSwift

class LitecoinAdapter: BitcoinBaseAdapter {
    private let litecoinKit: LitecoinKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode) throws {
        let networkType: LitecoinKit.Kit.NetworkType = .mainNet
        let logger = App.shared.logger.scoped(with: "LitecoinKit")

        let hasher: (Data) -> Data = { data in
            let params = LitecoinKit.Kit.defaultScryptParams

            let result = try? BackupCryptoHelper.makeScrypt(
                pass: data,
                salt: data,
                dkLen: params.length,
                N: params.N,
                r: params.r,
                p: params.p
            )
            return result ?? Data()
        }

        switch wallet.account.type {
        case .mnemonic:
            guard let seed = wallet.account.type.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }

            guard let derivation = wallet.token.type.derivation else {
                throw AdapterError.wrongParameters
            }

            litecoinKit = try LitecoinKit.Kit(
                seed: seed,
                purpose: derivation.purpose,
                walletId: wallet.account.id,
                syncMode: syncMode,
                hasher: hasher,
                networkType: networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: logger
            )
        case let .hdExtendedKey(key):
            guard let derivation = wallet.token.type.derivation else {
                throw AdapterError.wrongParameters
            }

            litecoinKit = try LitecoinKit.Kit(
                extendedKey: key,
                purpose: derivation.purpose,
                walletId: wallet.account.id,
                syncMode: syncMode,
                hasher: hasher,
                networkType: networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: logger
            )
        default:
            throw AdapterError.unsupportedAccount
        }

        super.init(abstractKit: litecoinKit, wallet: wallet)

        litecoinKit.delegate = self
    }

    override var explorerTitle: String {
        "blockchair.com"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        "https://blockchair.com/litecoin/transaction/" + transactionHash
    }
}

extension LitecoinAdapter: ISendBitcoinAdapter {
    var blockchainType: BlockchainType {
        .litecoin
    }
}

extension LitecoinAdapter {
    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }
}
