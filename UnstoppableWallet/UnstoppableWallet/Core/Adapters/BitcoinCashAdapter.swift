import BitcoinCashKit
import RxSwift

class BitcoinCashAdapter: BitcoinBaseAdapter {
    private let bitcoinCashKit: Kit

    init(wallet: Wallet, syncMode: SyncMode, testMode: Bool) throws {
        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        guard let bitcoinCashCoinType = wallet.coinSettings.bitcoinCashCoinType else {
            throw AdapterError.wrongParameters
        }

        let kitCoinType: BitcoinCashKit.CoinType

        switch bitcoinCashCoinType {
        case .type0: kitCoinType = .type0
        case .type145: kitCoinType = .type145
        }

        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet(coinType: kitCoinType)
        let logger = App.shared.logger.scoped(with: "BitcoinCashKit")

        bitcoinCashKit = try Kit(seed: seed, walletId: wallet.account.id, syncMode: BitcoinBaseAdapter.kitMode(from: syncMode), networkType: networkType, confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold, logger: logger)

        super.init(abstractKit: bitcoinCashKit, wallet: wallet, testMode: testMode)

        bitcoinCashKit.delegate = self
    }

    override var explorerTitle: String {
        "btc.com"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        testMode ? nil : "https://bch.btc.com/" + transactionHash
    }

}

extension BitcoinCashAdapter: ISendBitcoinAdapter {
}

extension BitcoinCashAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }

}
