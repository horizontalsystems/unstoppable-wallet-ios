import LitecoinKit
import BitcoinCore
import RxSwift

class LitecoinAdapter: BitcoinBaseAdapter {
    private let litecoinKit: Kit

    init(wallet: Wallet, syncMode: SyncMode, testMode: Bool) throws {
        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        guard let walletDerivation = wallet.configuredCoin.settings.derivation else {
            throw AdapterError.wrongParameters
        }

        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet
        let bip = BitcoinBaseAdapter.bip(from: walletDerivation)
        let syncMode = BitcoinBaseAdapter.kitMode(from: syncMode)
        let logger = App.shared.logger.scoped(with: "LitecoinKit")

        litecoinKit = try Kit(seed: seed, bip: bip, walletId: wallet.account.id, syncMode: syncMode, networkType: networkType, confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold, logger: logger)

        super.init(abstractKit: litecoinKit, wallet: wallet)

        litecoinKit.delegate = self
    }

}

extension LitecoinAdapter: ISendBitcoinAdapter {
}

extension LitecoinAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }

}
