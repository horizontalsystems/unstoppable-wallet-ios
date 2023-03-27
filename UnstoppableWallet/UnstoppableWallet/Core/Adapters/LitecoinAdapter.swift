import LitecoinKit
import BitcoinCore
import RxSwift
import MarketKit
import HdWalletKit

class LitecoinAdapter: BitcoinBaseAdapter {
    private let litecoinKit: LitecoinKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode) throws {
        let networkType: LitecoinKit.Kit.NetworkType = .mainNet
        let logger = App.shared.logger.scoped(with: "LitecoinKit")

        switch wallet.account.type {
        case .mnemonic:
            guard let seed = wallet.account.type.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }

            guard let derivation = wallet.coinSettings.derivation else {
                throw AdapterError.wrongParameters
            }

            litecoinKit = try LitecoinKit.Kit(
                    seed: seed,
                    purpose: derivation.purpose,
                    walletId: wallet.account.id,
                    syncMode: syncMode,
                    networkType: networkType,
                    confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                    logger: logger
            )
        case let .hdExtendedKey(key):
            guard let derivation = wallet.coinSettings.derivation else {
                throw AdapterError.wrongParameters
            }

            litecoinKit = try LitecoinKit.Kit(
                    extendedKey: key,
                    purpose: derivation.purpose,
                    walletId: wallet.account.id,
                    syncMode: syncMode,
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
