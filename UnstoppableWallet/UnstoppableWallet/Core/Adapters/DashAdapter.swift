import BitcoinCore
import DashKit
import Foundation
import HdWalletKit
import HsToolKit
import MarketKit
import RxSwift

class DashAdapter: BitcoinBaseAdapter {
    static let networkType: DashKit.Kit.NetworkType = .mainNet
    private let feeRate = 1

    private let dashKit: DashKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode) throws {
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
                networkType: Self.networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: logger
            )
        case let .hdExtendedKey(key):
            dashKit = try DashKit.Kit(
                extendedKey: key,
                walletId: wallet.account.id,
                syncMode: syncMode,
                networkType: Self.networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: logger
            )
        case let .btcAddress(address, _, _):
            dashKit = try DashKit.Kit(
                watchAddress: address,
                walletId: wallet.account.id,
                syncMode: syncMode,
                networkType: Self.networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: logger
            )
        default:
            throw AdapterError.unsupportedAccount
        }

        super.init(abstractKit: dashKit, wallet: wallet, syncMode: syncMode)

        dashKit.delegate = self
    }

    override var explorerTitle: String {
        "dash.org"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        "https://insight.dash.org/insight/tx/" + transactionHash
    }

    override func explorerUrl(address: String) -> String? {
        "https://insight.dash.org/insight/address/" + address
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

    static func firstAddress(accountType: AccountType) throws -> String {
        switch accountType {
        case .mnemonic:
            guard let seed = accountType.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }

            let address = try DashKit.Kit.firstAddress(
                seed: seed,
                networkType: networkType
            )

            return address.stringValue
        case let .hdExtendedKey(key):
            let address = try DashKit.Kit.firstAddress(
                extendedKey: key,
                networkType: networkType
            )

            return address.stringValue
        case let .btcAddress(address, _, _):
            return address
        default:
            throw AdapterError.unsupportedAccount
        }
    }
}
