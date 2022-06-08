import BitcoinKit
import BitcoinCore
import RxSwift
import MarketKit

class BitcoinAdapter: BitcoinBaseAdapter {
    private let bitcoinKit: BitcoinKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode, testMode: Bool) throws {
        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        guard let walletDerivation = wallet.coinSettings.derivation else {
            throw AdapterError.wrongParameters
        }

        let networkType: BitcoinKit.Kit.NetworkType = testMode ? .testNet : .mainNet
        let bip = BitcoinBaseAdapter.bip(from: walletDerivation)
        let logger = App.shared.logger.scoped(with: "BitcoinKit")

        bitcoinKit = try BitcoinKit.Kit(seed: seed, bip: bip, walletId: wallet.account.id, syncMode: syncMode, networkType: networkType, confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold, logger: logger)

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
