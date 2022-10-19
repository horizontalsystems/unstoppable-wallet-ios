import BitcoinKit
import BitcoinCore
import RxSwift
import HdWalletKit
import MarketKit

class BitcoinAdapter: BitcoinBaseAdapter {
    private let bitcoinKit: BitcoinKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode, testMode: Bool) throws {
        let networkType: BitcoinKit.Kit.NetworkType = testMode ? .testNet : .mainNet
        let logger = App.shared.logger.scoped(with: "BitcoinKit")

        switch wallet.account.type {
        case let .mnemonic(words, salt):
            guard let seed = Mnemonic.seed(mnemonic: words, passphrase: salt) else {
                throw AdapterError.unsupportedAccount
            }

            guard let derivation = wallet.coinSettings.derivation else {
                throw AdapterError.wrongParameters
            }

            bitcoinKit = try BitcoinKit.Kit(
                    seed: seed,
                    purpose: derivation.purpose,
                    walletId: wallet.account.id,
                    syncMode: syncMode,
                    networkType: networkType,
                    confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                    logger: logger
            )
        case let .hdExtendedKey(key):
            bitcoinKit = try BitcoinKit.Kit(
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

        super.init(abstractKit: bitcoinKit, wallet: wallet, testMode: testMode)

        bitcoinKit.delegate = self
    }

    override var explorerTitle: String {
        "blockchair.com"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        testMode ? nil : "https://blockchair.com/bitcoin/transaction/" + transactionHash
    }

}

extension BitcoinAdapter: ISendBitcoinAdapter {

    var blockchainType: BlockchainType {
        .bitcoin
    }

}

extension BitcoinAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }

}
