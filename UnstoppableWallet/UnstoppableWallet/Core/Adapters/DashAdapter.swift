import Foundation
import DashKit
import RxSwift
import HsToolKit
import BitcoinCore

class DashAdapter: BitcoinBaseAdapter {
    private let feeRate = 1

    private let dashKit: Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode, testMode: Bool) throws {
        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet
        let logger = App.shared.logger.scoped(with: "DashKit")

        dashKit = try Kit(seed: seed, walletId: wallet.account.id, syncMode: syncMode, networkType: networkType, confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold, logger: logger)

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

    var blockchain: BtcBlockchain {
        .dash
    }

}

extension DashAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }

}
