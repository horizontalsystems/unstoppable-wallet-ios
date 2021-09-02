import BitcoinKit
import BitcoinCore
import RxSwift

class BitcoinAdapterNew: BitcoinBaseAdapterNew {
    private let bitcoinKit: Kit

    init(wallet: WalletNew, syncMode: SyncMode, testMode: Bool) throws {
        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        guard let walletDerivation = wallet.coinSettings.derivation else {
            throw AdapterError.wrongParameters
        }

        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet
        let bip = BitcoinBaseAdapter.bip(from: walletDerivation)
        let syncMode = BitcoinBaseAdapter.kitMode(from: syncMode)
        let logger = App.shared.logger.scoped(with: "BitcoinKit")

        bitcoinKit = try Kit(seed: seed, bip: bip, walletId: wallet.account.id, syncMode: syncMode, networkType: networkType, confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold, logger: logger)

        super.init(abstractKit: bitcoinKit, wallet: wallet)

        bitcoinKit.delegate = self
    }

}

extension BitcoinAdapterNew: ISendBitcoinAdapter {
}

extension BitcoinAdapterNew {

    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }

}
