import BitcoinCashKit
import BitcoinCore
import HdWalletKit
import MarketKit
import RxSwift

class BitcoinCashAdapter: BitcoinBaseAdapter {
    private let bitcoinCashKit: BitcoinCashKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode) throws {
        guard let bitcoinCashCoinType = wallet.token.type.bitcoinCashCoinType else {
            throw AdapterError.wrongParameters
        }

        let kitCoinType: BitcoinCashKit.CoinType

        switch bitcoinCashCoinType {
        case .type0: kitCoinType = .type0
        case .type145: kitCoinType = .type145
        }

        let networkType: BitcoinCashKit.Kit.NetworkType = .mainNet(coinType: kitCoinType)
        let logger = App.shared.logger.scoped(with: "BitcoinCashKit")

        switch wallet.account.type {
        case .mnemonic:
            guard let seed = wallet.account.type.mnemonicSeed else {
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
        case let .btcAddress(address, _, _):
            bitcoinCashKit = try BitcoinCashKit.Kit(
                watchAddress: address,
                walletId: wallet.account.id,
                syncMode: syncMode,
                networkType: networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: nil
            )
        default:
            throw AdapterError.unsupportedAccount
        }

        super.init(abstractKit: bitcoinCashKit, wallet: wallet, syncMode: syncMode)

        bitcoinCashKit.delegate = self
    }

    override var explorerTitle: String {
        "btc.com"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        "https://bch.btc.com/" + transactionHash
    }

    override func explorerUrl(address: String) -> String? {
        "https://bch.btc.com/bch/address/" + address
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
