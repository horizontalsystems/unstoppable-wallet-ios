import Foundation
import MarketKit
import StellarKit

class StellarOperationConverter {
    private let accountId: String
    private let source: TransactionSource
    private let baseToken: Token
    private let coinManager: CoinManager

    init(accountId: String, source: TransactionSource, baseToken: Token, coinManager: CoinManager) {
        self.accountId = accountId
        self.source = source
        self.baseToken = baseToken
        self.coinManager = coinManager
    }

    private func assetValue(asset: Asset, value: Decimal) -> AppValue {
        AppValue(kind: assetKind(asset: asset), value: value)
    }

    private func assetKind(asset: Asset) -> AppValue.Kind {
        let tokenType: TokenType

        switch asset {
        case .native: tokenType = .native
        case let .asset(code, issuer): tokenType = .stellar(code: code, issuer: issuer)
        }

        let query = TokenQuery(blockchainType: .stellar, tokenType: tokenType)

        if let token = try? coinManager.token(query: query) {
            return .token(token: token)
        } else {
            return .stellar(asset: asset)
        }
    }

    private func type(type: TxOperation.`Type`) -> StellarTransactionRecord.`Type` {
        switch type {
        case let .accountCreated(data):
            if data.account == accountId {
                return .accountCreated(startingBalance: AppValue(token: baseToken, value: data.startingBalance), funder: data.funder)
            } else {
                return .accountFunded(startingBalance: AppValue(token: baseToken, value: -data.startingBalance), account: data.account)
            }
        case let .payment(data):
            if data.from == accountId {
                return .sendPayment(value: assetValue(asset: data.asset, value: -data.amount), to: data.to, sentToSelf: data.to == accountId)
            } else {
                return .receivePayment(value: assetValue(asset: data.asset, value: data.amount), from: data.from)
            }
        case let .pathPayment(data):
            if data.from == accountId, data.to == accountId {
                // The common DEX shape: the swap settles on the own account.
                return .swap(
                    valueIn: assetValue(asset: data.sourceAsset, value: -data.sourceAmount),
                    valueOut: assetValue(asset: data.asset, value: data.amount)
                )
            } else if data.from == accountId {
                // Swap paid out to a third party: from this account's view it spent the source asset.
                return .sendPayment(value: assetValue(asset: data.sourceAsset, value: -data.sourceAmount), to: data.to, sentToSelf: false)
            } else {
                return .receivePayment(value: assetValue(asset: data.asset, value: data.amount), from: data.from)
            }
        case let .changeTrust(data):
            return .changeTrust(value: assetValue(asset: data.asset, value: data.limit), trustor: data.trustor, trustee: data.trustee, liquidityPoolId: data.liquidityPoolId)
        case let .invokeHostFunction(data):
            // Net this account's per-asset movements from the balance changes. One net spend +
            // one net gain = a swap (fee side-transfers in the spent asset fold into its net).
            // Anything else falls through as a labeled contract invocation.
            var deltas = [Asset: Decimal]()
            for change in data.balanceChanges {
                if change.from == accountId { deltas[change.asset, default: 0] -= change.amount }
                if change.to == accountId { deltas[change.asset, default: 0] += change.amount }
            }
            let spent = deltas.filter { $0.value < 0 }
            let gained = deltas.filter { $0.value > 0 }

            if spent.count == 1, gained.count == 1, let out = spent.first, let inn = gained.first {
                return .swap(
                    valueIn: assetValue(asset: out.key, value: out.value),
                    valueOut: assetValue(asset: inn.key, value: inn.value)
                )
            }
            if spent.isEmpty, gained.count == 1, let inn = gained.first {
                return .receivePayment(value: assetValue(asset: inn.key, value: inn.value), from: data.balanceChanges.first(where: { $0.to == accountId })?.from ?? "")
            }
            return .unsupported(type: data.function)
        case let .unknown(rawType):
            return .unsupported(type: rawType)
        }
    }
}

extension StellarOperationConverter {
    func transactionRecord(operation: TxOperation) -> StellarTransactionRecord {
        let type = type(type: operation.type)

        return StellarTransactionRecord(source: source, operation: operation, baseToken: baseToken, type: type, spam: false)
    }
}
