import BitcoinCore
import BitcoinKit
import HdWalletKit
import MarketKit
import RxSwift

class BitcoinAdapter: BitcoinBaseAdapter {
    private let bitcoinKit: BitcoinKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode) throws {
        let networkType: BitcoinKit.Kit.NetworkType = .mainNet
        let logger = App.shared.logger.scoped(with: "BitcoinKit")

        switch wallet.account.type {
        case .mnemonic:
            guard let seed = wallet.account.type.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }

            guard let derivation = wallet.token.type.derivation else {
                throw AdapterError.wrongParameters
            }

            bitcoinKit = try BitcoinKit.Kit(
                seed: seed,
                purpose: derivation.purpose,
                walletId: wallet.account.id,
                syncMode: syncMode,
                networkType: networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: logger
            )
        case let .hdExtendedKey(key):
            guard let derivation = wallet.token.type.derivation else {
                throw AdapterError.wrongParameters
            }

            bitcoinKit = try BitcoinKit.Kit(
                extendedKey: key,
                purpose: derivation.purpose,
                walletId: wallet.account.id,
                syncMode: syncMode,
                networkType: networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: logger
            )
        case let .btcAddress(address, _, tokenType):
            guard let purpose = tokenType.derivation?.purpose else {
                throw AdapterError.wrongParameters
            }

            bitcoinKit = try BitcoinKit.Kit(
                watchAddress: address,
                purpose: purpose,
                walletId: wallet.account.id,
                syncMode: syncMode,
                networkType: networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: logger
            )
        default:
            throw AdapterError.unsupportedAccount
        }

        super.init(abstractKit: bitcoinKit, wallet: wallet, syncMode: syncMode)

        bitcoinKit.delegate = self
    }

    override var explorerTitle: String {
        "blockchair.com"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        "https://blockchair.com/bitcoin/transaction/" + transactionHash
    }

    override func explorerUrl(address: String) -> String? {
        "https://blockchair.com/bitcoin/address/" + address
    }
}

extension BitcoinAdapter: ISendBitcoinAdapter {
    var blockchainType: BlockchainType {
        .bitcoin
    }
}

extension BitcoinAdapter {
    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }
}
