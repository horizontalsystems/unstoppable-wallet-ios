import Foundation
import MarketKit

struct OpenCryptoPayPayment: Equatable {
    let quoteId: String
    let quoteExpirationDate: Date
    let callback: URL
    let recipient: Recipient
    let entries: [Entry]
    let capturedAccountId: String

    struct Entry: Equatable, Identifiable {
        let id: String
        let method: String
        let blockchainType: BlockchainType
        let asset: String
        let displayAmount: Decimal
        let token: Token
    }

    struct Recipient: Equatable {
        let name: String
        let mail: String?
        let website: String?
    }

    func entry(for wallet: Wallet) -> Entry? {
        entries.first { $0.token == wallet.token }
    }
}

extension OpenCryptoPayPayment {
    enum Validator {
        private static let allowedHandledParams: Set<AddressUri.Field> = [
            .value, .amount, .txAmount, .memo, .txDescription, .message, .label,
            .blockchainUid, .tokenUid,
        ]
        private static let blacklistedUriParams: Set<String> = [
            "data", "to", "gas", "gaslimit", "gasprice",
        ]

        static func validateSession(_ payment: OpenCryptoPayPayment) throws {
            guard payment.quoteExpirationDate > Date() else {
                throw OpenCryptoPayManager.Error.quoteExpired
            }
            guard !payment.entries.isEmpty else {
                throw OpenCryptoPayManager.Error.noSupportedMethod
            }
        }

        static func validate(txDetails: OpenCryptoPayProvider.Models.TransactionDetails, against payment: OpenCryptoPayPayment, wallet: Wallet) throws -> SendTokenListViewModel.SendOptions {
            guard txDetails.expiryDate > Date() else {
                throw OpenCryptoPayManager.Error.quoteExpired
            }

            guard let entry = payment.entry(for: wallet) else {
                throw OpenCryptoPayManager.Error.chainMismatch
            }

            let parser = AddressUriParser(blockchainType: wallet.token.blockchainType, tokenType: wallet.token.type)
            let uri: AddressUri
            do {
                uri = try parser.parse(url: txDetails.uri)
            } catch AddressUriParser.ParseError.invalidBlockchainType, AddressUriParser.ParseError.invalidTokenType {
                throw OpenCryptoPayManager.Error.chainMismatch
            } catch {
                throw OpenCryptoPayManager.Error.malformedTxUri
            }

            for key in uri.unhandledParameters.keys {
                if blacklistedUriParams.contains(key.lowercased()) {
                    throw OpenCryptoPayManager.Error.unsupportedTxParameter(key)
                }
            }

            try validateChain(uri: uri, txDetails: txDetails, wallet: wallet)
            try validateHandledKeys(uri: uri, wallet: wallet)

            if let allowed = uri.allowedBlockchainTypes, !allowed.contains(wallet.token.blockchainType) {
                throw OpenCryptoPayManager.Error.chainMismatch
            }

            try validateAmount(uri: uri, expected: entry.displayAmount, token: wallet.token)

            return SendTokenListViewModel.SendOptions(
                address: uri.address,
                amount: uri.amount,
                memo: uri.memo
            )
        }

        private static func validateChain(uri: AddressUri, txDetails: OpenCryptoPayProvider.Models.TransactionDetails, wallet: Wallet) throws {
            if let uid = uri.parameters[.blockchainUid] {
                if BlockchainType(uid: uid) != wallet.token.blockchainType {
                    throw OpenCryptoPayManager.Error.chainMismatch
                }
            }
            guard let blockchain = Core.shared.openCryptoPayManager.broadcasterFactory.supportedChains[txDetails.blockchain] else {
                throw OpenCryptoPayManager.Error.chainMismatch
            }
            if blockchain != wallet.token.blockchainType {
                throw OpenCryptoPayManager.Error.chainMismatch
            }
        }

        private static func validateHandledKeys(uri: AddressUri, wallet: Wallet) throws {
            for (key, value) in uri.parameters {
                if !allowedHandledParams.contains(key) {
                    throw OpenCryptoPayManager.Error.unsupportedTxParameter(key.rawValue)
                }
                if case .blockchainUid = key {
                    if BlockchainType(uid: value) != wallet.token.blockchainType {
                        throw OpenCryptoPayManager.Error.chainMismatch
                    }
                }
            }
        }

        private static func validateAmount(uri: AddressUri, expected: Decimal, token: Token) throws {
            guard let amount = uri.amount else {
                throw OpenCryptoPayManager.Error.amountMismatch
            }
            let expectedBase = expected.fromReadable(decimals: token.decimals)
            let actualBase: Decimal
            switch amount {
            case let .points(v): actualBase = v
            case let .decimals(v): actualBase = v.fromReadable(decimals: token.decimals)
            }
            if actualBase != expectedBase {
                throw OpenCryptoPayManager.Error.amountMismatch
            }
        }
    }
}
