import BitcoinCashKit
import BitcoinCore
import RxSwift
import MarketKit
import HdWalletKit

class BitcoinCashAdapter: BitcoinBaseAdapter {
    private let bitcoinCashKit: BitcoinCashKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode, testMode: Bool) throws {
        guard let bitcoinCashCoinType = wallet.coinSettings.bitcoinCashCoinType else {
            throw AdapterError.wrongParameters
        }

        let kitCoinType: BitcoinCashKit.CoinType

        switch bitcoinCashCoinType {
        case .type0: kitCoinType = .type0
        case .type145: kitCoinType = .type145
        }

        let networkType: BitcoinCashKit.Kit.NetworkType = testMode ? .testNet : .mainNet(coinType: kitCoinType)
        let logger = App.shared.logger.scoped(with: "BitcoinCashKit")

        switch wallet.account.type {
        case let .mnemonic(words, salt):
            guard let seed = Mnemonic.seed(mnemonic: words, passphrase: salt) else {
                throw AdapterError.unsupportedAccount
            }

            bitcoinCashKit = try BitcoinCashKit.Kit(
                    seed: seed,
                    walletId: wallet.account.id,
                    syncMode: syncMode,
                    networkType: networkType,
                    confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                    logger: logger
            )
        case let .hdExtendedKey(key):
            bitcoinCashKit = try BitcoinCashKit.Kit(
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

    var blockchainType: BlockchainType {
        .bitcoinCash
    }

}

extension BitcoinCashAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }

}
