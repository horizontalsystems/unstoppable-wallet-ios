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

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode) throws {
        let networkType: DashKit.Kit.NetworkType = .mainNet
        let logger = App.shared.logger.scoped(with: "DashKit")

        switch wallet.account.type {
        case .mnemonic:
            guard let seed = wallet.account.type.mnemonicSeed else {
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

        super.init(abstractKit: dashKit, wallet: wallet)

        dashKit.delegate = self
    }

    override var explorerTitle: String {
        "dash.org"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        "https://insight.dash.org/insight/tx/" + transactionHash
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
