import Foundation
import DashKit
import RxSwift
import HsToolKit
import BitcoinCore
import MarketKit
import HdWalletKit

class DashAdapter: BitcoinBaseAdapter {
    private let feeRate = 1

    private let dashKit: DashKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode, testMode: Bool) throws {
        let networkType: DashKit.Kit.NetworkType = testMode ? .testNet : .mainNet
        let logger = App.shared.logger.scoped(with: "DashKit")

        switch wallet.account.type {
        case let .mnemonic(words, salt):
            guard let seed = Mnemonic.seed(mnemonic: words, passphrase: salt) else {
                throw AdapterError.unsupportedAccount
            }

            dashKit = try DashKit.Kit(
                    seed: seed,
                    walletId: wallet.account.id,
                    syncMode: syncMode,
                    networkType: networkType,
                    confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                    logger: logger
            )
        case let .hdExtendedKey(key):
            dashKit = try DashKit.Kit(
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

        super.init(abstractKit: dashKit, wallet: wallet, testMode: testMode)

        dashKit.delegate = self
    }

    override var explorerTitle: String {
        "dash.org"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        testMode ? nil : "https://insight.dash.org/insight/tx/" + transactionHash
    }

}

extension DashAdapter: DashKitDelegate {

    public func transactionsUpdated(inserted: [DashTransactionInfo], updated: [DashTransactionInfo]) {
        var records = [BitcoinTransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }

}

extension DashAdapter: ISendBitcoinAdapter {

    var blockchainType: BlockchainType {
        .dash
    }

}

extension DashAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }

}
