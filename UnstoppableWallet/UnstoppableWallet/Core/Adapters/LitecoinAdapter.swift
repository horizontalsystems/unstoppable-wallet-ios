import BitcoinCore
import Foundation
import HdWalletKit
import LitecoinKit
import MarketKit
import RxSwift

class LitecoinAdapter: BitcoinBaseAdapter {
    private static let networkType: LitecoinKit.Kit.NetworkType = .mainNet
    private let litecoinKit: LitecoinKit.Kit

    init(wallet: Wallet, syncMode: BitcoinCore.SyncMode) throws {
        let logger = App.shared.logger.scoped(with: "LitecoinKit")

        let hasher: (Data) -> Data = { data in
            let params = LitecoinKit.Kit.defaultScryptParams

            let result = try? BackupCryptoHelper.makeScrypt(
                pass: data,
                salt: data,
                dkLen: params.length,
                N: params.N,
                r: params.r,
                p: params.p
            )
            return result ?? Data()
        }

        switch wallet.account.type {
        case .mnemonic:
            guard let seed = wallet.account.type.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }

            guard let derivation = wallet.token.type.derivation else {
                throw AdapterError.wrongParameters
            }

            litecoinKit = try LitecoinKit.Kit(
                seed: seed,
                purpose: derivation.purpose,
                walletId: wallet.account.id,
                syncMode: syncMode,
                hasher: hasher,
                networkType: Self.networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: logger
            )
        case let .hdExtendedKey(key):
            guard let derivation = wallet.token.type.derivation else {
                throw AdapterError.wrongParameters
            }

            litecoinKit = try LitecoinKit.Kit(
                extendedKey: key,
                purpose: derivation.purpose,
                walletId: wallet.account.id,
                syncMode: syncMode,
                hasher: hasher,
                networkType: Self.networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: logger
            )
        case let .btcAddress(address, _, tokenType):
            guard let purpose = tokenType.derivation?.purpose else {
                throw AdapterError.wrongParameters
            }

            litecoinKit = try LitecoinKit.Kit(
                watchAddress: address,
                purpose: purpose,
                walletId: wallet.account.id,
                syncMode: syncMode,
                hasher: hasher,
                networkType: Self.networkType,
                confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold,
                logger: logger
            )
        default:
            throw AdapterError.unsupportedAccount
        }

        super.init(abstractKit: litecoinKit, wallet: wallet, syncMode: syncMode)

        litecoinKit.delegate = self
    }

    override var explorerTitle: String {
        "blockchair.com"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        "https://blockchair.com/litecoin/transaction/" + transactionHash
    }

    override func explorerUrl(address: String) -> String? {
        "https://blockchair.com/litecoin/address/" + address
    }
}

extension LitecoinAdapter: ISendBitcoinAdapter {
    var blockchainType: BlockchainType {
        .litecoin
    }
}

extension LitecoinAdapter {
    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }

    static func firstAddress(accountType: AccountType, tokenType: TokenType) throws -> String {
        switch accountType {
        case .mnemonic:
            guard let seed = accountType.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }

            guard let derivation = tokenType.derivation else {
                throw AdapterError.wrongParameters
            }

            let address = try LitecoinKit.Kit.firstAddress(
                seed: seed,
                purpose: derivation.purpose,
                networkType: Self.networkType
            )

            return address.stringValue
        case let .hdExtendedKey(key):
            guard let derivation = tokenType.derivation else {
                throw AdapterError.wrongParameters
            }

            let address = try LitecoinKit.Kit.firstAddress(
                extendedKey: key,
                purpose: derivation.purpose,
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
