import BitcoinCore
import ECashKit
import Foundation
import HdWalletKit
import MarketKit
import RxSwift

class ECashAdapter: BitcoinBaseAdapter {
    private static let eCashConfirmationsThreshold = 1
    override var coinRate: Decimal { 100 } // pow(10,2)

    private let eCashKit: ECashKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode) throws {
        let networkType: ECashKit.Kit.NetworkType = .mainNet
        let logger = App.shared.logger.scoped(with: "ECashKit")

        switch wallet.account.type {
        case .mnemonic:
            guard let seed = wallet.account.type.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }

            eCashKit = try ECashKit.Kit(
                    seed: seed,
                    walletId: wallet.account.id,
                    syncMode: syncMode,
                    networkType: networkType,
                    confirmationsThreshold: Self.eCashConfirmationsThreshold,
                    logger: logger
            )
        case let .hdExtendedKey(key):
            eCashKit = try ECashKit.Kit(
                    extendedKey: key,
                    walletId: wallet.account.id,
                    syncMode: syncMode,
                    networkType: networkType,
                    confirmationsThreshold: Self.eCashConfirmationsThreshold,
                    logger: logger
            )
        case let .btcAddress(address, _, _):
            eCashKit = try ECashKit.Kit(
                    watchAddress: address,
                    walletId: wallet.account.id,
                    syncMode: syncMode,
                    networkType: networkType,
                    confirmationsThreshold: Self.eCashConfirmationsThreshold,
                    logger: logger
            )
        default:
            throw AdapterError.unsupportedAccount
        }

        super.init(abstractKit: eCashKit, wallet: wallet, syncMode: syncMode)

        eCashKit.delegate = self
    }

    override var explorerTitle: String {
        "blockchair.com"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        "https://blockchair.com/ecash/transaction/" + transactionHash
    }

    override func explorerUrl(address: String) -> String? {
        "https://blockchair.com/ecash/address/" + address
    }
}

extension ECashAdapter: ISendBitcoinAdapter {
    var blockchainType: BlockchainType {
        .ecash
    }
}

extension ECashAdapter {
    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }
}
