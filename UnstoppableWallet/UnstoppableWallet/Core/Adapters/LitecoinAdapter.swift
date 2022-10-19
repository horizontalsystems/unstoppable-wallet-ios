import LitecoinKit
import BitcoinCore
import RxSwift
import MarketKit
import HdWalletKit

class LitecoinAdapter: BitcoinBaseAdapter {
    private let litecoinKit: LitecoinKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode, testMode: Bool) throws {
        let networkType: LitecoinKit.Kit.NetworkType = testMode ? .testNet : .mainNet
        let logger = App.shared.logger.scoped(with: "LitecoinKit")

        switch wallet.account.type {
        case let .mnemonic(words, salt):
            guard let seed = Mnemonic.seed(mnemonic: words, passphrase: salt) else {
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
            litecoinKit = try LitecoinKit.Kit(
                    extendedKey: key,
                    walletId: wallet.account.id,
                    syncMode: syncMode,
                    networkType: networkType,
                    confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                    logger: logger
            )
        default:
            throw AdapterError.unsupportedAccount
        }

        super.init(abstractKit: litecoinKit, wallet: wallet, testMode: testMode)

        litecoinKit.delegate = self
    }

    override var explorerTitle: String {
        "blockchair.com"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        testMode ? nil : "https://blockchair.com/litecoin/transaction/" + transactionHash
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
