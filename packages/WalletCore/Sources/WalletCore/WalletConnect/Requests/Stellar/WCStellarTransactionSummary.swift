import Foundation
import stellarsdk

/// Disclosure only: reads the SDK's decoded operations without changing the envelope to sign.
struct WCStellarTransactionSummary {
    struct Field {
        enum Style { case text, address, hex }

        let titleKey: String
        let value: String
        var style: Style = .text
    }

    struct OperationSummary {
        let title: String
        let fields: [Field]
    }

    enum Warning: Hashable {
        case accountPermissions
        case unknownOperations
    }

    let operations: [OperationSummary]
    let memoFields: [Field]
    let warnings: [Warning]

    init(transaction: stellarsdk.Transaction) {
        var warnings = Set<Warning>()
        let source = transaction.transactionXDR.sourceAccount.accountId
        operations = transaction.operations.map { Self.summarize($0, transactionSource: source, warnings: &warnings) }
        memoFields = Self.memoFields(transaction.memo)
        self.warnings = [.accountPermissions, .unknownOperations].filter { warnings.contains($0) }
    }

    private static func summarize(_ operation: stellarsdk.Operation, transactionSource: String, warnings: inout Set<Warning>) -> OperationSummary {
        let prefix = "wallet_connect.stellar."
        var fields = [Field(titleKey: prefix + "source", value: operation.sourceAccountId ?? transactionSource, style: .address)]
        let title: String

        switch operation {
        case let payment as PaymentOperation:
            title = prefix + "payment"
            fields.append(Field(titleKey: "send.confirmation.to", value: payment.destinationAccountId, style: .address))
            fields.append(amount("amount", payment.amount, payment.asset))
            fields += issuer(payment.asset, title: "issuer")
        case let create as CreateAccountOperation:
            title = prefix + "create_account"
            fields.append(Field(titleKey: "send.confirmation.to", value: create.destination.accountId, style: .address))
            fields.append(Field(titleKey: prefix + "amount", value: number(create.startBalance) + " XLM"))
        case let merge as AccountMergeOperation:
            title = prefix + "account_merge"
            fields.append(Field(titleKey: "send.confirmation.to", value: merge.destinationAccountId, style: .address))
        case let path as PathPaymentOperation:
            // The SDK reuses sendMax/destAmount for strict-send's exact input/minimum output.
            let strictSend = path is PathPaymentStrictSendOperation
            title = prefix + (strictSend ? "path_payment_send" : "path_payment_receive")
            fields.append(Field(titleKey: "send.confirmation.to", value: path.destinationAccountId, style: .address))
            fields.append(amount(strictSend ? "send_amount" : "send_max", path.sendMax, path.sendAsset))
            fields += issuer(path.sendAsset, title: "send_issuer")
            fields.append(amount(strictSend ? "receive_min" : "receive_amount", path.destAmount, path.destAsset))
            fields += issuer(path.destAsset, title: "receive_issuer")
        case let trust as ChangeTrustOperation:
            title = prefix + "change_trust"
            if trust.asset.type == AssetType.ASSET_TYPE_POOL_SHARE {
                fields.append(Field(titleKey: prefix + "asset", value: (prefix + "pool_share").localized))
                warnings.insert(.unknownOperations)
            } else {
                fields.append(Field(titleKey: prefix + "asset", value: assetCode(trust.asset)))
                fields += issuer(trust.asset, title: "issuer")
            }
            let limit = trust.limit ?? Decimal(Int64.max) / 10_000_000
            fields.append(Field(titleKey: prefix + "limit", value: number(limit)))
        case let offer as ManageOfferOperation:
            let buy = offer is ManageBuyOfferOperation
            title = prefix + (buy ? "manage_buy_offer" : "manage_sell_offer")
            fields += offerFields(selling: offer.selling, buying: offer.buying, amount: offer.amount, price: offer.price, buy: buy)
            fields.append(Field(titleKey: prefix + "offer_id", value: String(offer.offerId)))
        case let offer as CreatePassiveOfferOperation:
            title = prefix + "passive_sell_offer"
            fields += offerFields(selling: offer.selling, buying: offer.buying, amount: offer.amount, price: offer.price, buy: false)
        case let options as SetOptionsOperation:
            title = prefix + "set_options"
            warnings.insert(.accountPermissions)
            let values: [(String, UInt32?)] = [
                ("master_weight", options.masterKeyWeight), ("low_threshold", options.lowThreshold),
                ("medium_threshold", options.mediumThreshold), ("high_threshold", options.highThreshold),
                ("set_flags", options.setFlags), ("clear_flags", options.clearFlags),
            ]
            for (key, value) in values {
                if let value { fields.append(Field(titleKey: prefix + key, value: String(value))) }
            }
            if let destination = options.inflationDestination {
                fields.append(Field(titleKey: prefix + "inflation_destination", value: destination.accountId, style: .address))
            }
            if let domain = options.homeDomain {
                fields.append(Field(titleKey: prefix + "home_domain", value: domain.isEmpty ? "\"\"" : domain))
            }
            if let signer = options.signer {
                fields += signerFields(signer)
                if let weight = options.signerWeight {
                    fields.append(Field(titleKey: prefix + "signer_weight", value: String(weight)))
                }
            }
        default:
            title = String(describing: type(of: operation))
            warnings.insert(.unknownOperations)
        }

        return OperationSummary(title: title, fields: fields)
    }

    private static func assetCode(_ asset: stellarsdk.Asset) -> String {
        asset.type == AssetType.ASSET_TYPE_NATIVE ? "XLM" : (asset.code ?? "?")
    }

    private static func number(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    private static func amount(_ title: String, _ value: Decimal, _ asset: stellarsdk.Asset) -> Field {
        Field(titleKey: "wallet_connect.stellar." + title, value: number(value) + " " + assetCode(asset))
    }

    private static func issuer(_ asset: stellarsdk.Asset, title: String) -> [Field] {
        guard let issuer = asset.issuer else { return [] }
        return [Field(titleKey: "wallet_connect.stellar." + title, value: issuer.accountId, style: .address)]
    }

    private static func offerFields(selling: stellarsdk.Asset, buying: stellarsdk.Asset, amount value: Decimal, price: Price, buy: Bool) -> [Field] {
        var fields = [Field(titleKey: "wallet_connect.stellar.selling_asset", value: assetCode(selling))]
        fields += issuer(selling, title: "selling_issuer")
        fields.append(Field(titleKey: "wallet_connect.stellar.buying_asset", value: assetCode(buying)))
        fields += issuer(buying, title: "buying_issuer")
        fields.append(amount(buy ? "buy_amount" : "sell_amount", value, buy ? buying : selling))
        // Keep the exact ratio, including malformed denominators, without rounding or division.
        fields.append(Field(titleKey: "wallet_connect.stellar." + (buy ? "buy_price" : "sell_price"), value: "\(price.n)/\(price.d)"))
        return fields
    }

    private static func signerFields(_ signer: SignerKeyXDR) -> [Field] {
        let type: String
        let value: String
        let style: Field.Style
        var payload: Data?

        switch signer {
        case let .ed25519(key):
            type = "Ed25519"
            value = (try? PublicKey(Array(key.wrapped)).accountId) ?? hex(key.wrapped)
            style = .address
        case let .preAuthTx(key):
            type = "Pre-authorized transaction"
            value = hex(key.wrapped)
            style = .hex
        case let .hashX(key):
            type = "Hash X"
            value = hex(key.wrapped)
            style = .hex
        case let .signedPayload(key):
            type = "Ed25519 signed payload"
            value = (try? PublicKey(Array(key.ed25519.wrapped)).accountId) ?? hex(key.ed25519.wrapped)
            style = .address
            payload = key.payload
        }

        var fields = [Field(titleKey: "wallet_connect.stellar.signer_type", value: type),
                      Field(titleKey: "wallet_connect.stellar.signer", value: value, style: style)]
        if let payload { fields.append(Field(titleKey: "wallet_connect.stellar.signer_payload", value: hex(payload), style: .hex)) }
        return fields
    }

    private static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    private static func memoFields(_ memo: Memo) -> [Field] {
        switch memo {
        case .none: return []
        case let .text(text): return [Field(titleKey: "send.confirmation.memo", value: text.isEmpty ? "\"\"" : text)]
        case let .id(id): return [Field(titleKey: "wallet_connect.stellar.memo_id", value: String(id))]
        case let .hash(data): return [Field(titleKey: "wallet_connect.stellar.memo_hash", value: hex(data), style: .hex)]
        case let .returnHash(data): return [Field(titleKey: "wallet_connect.stellar.memo_return_hash", value: hex(data), style: .hex)]
        }
    }
}
