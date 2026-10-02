import Foundation
import MarketKit
import StellarKit

class StellarOperationConverter {
    private let accountId: String
    private let source: TransactionSource
    private let baseToken: Token
    private let coinManager: ICoinManager

    init(accountId: String, source: TransactionSource, baseToken: Token, coinManager: ICoinManager) {
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
            // Net this account's per-asset movements from the balance changes, as Android's
            // StellarContractMovement does. One net spend + one net gain = a swap (fee
            // side-transfers in the spent asset fold into its net); a single one-directional
            // movement = a plain send or receive; no movement or several assets in one direction
            // falls through as a labeled contract invocation.
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
            // A mint carries no `from` and a burn no `to`: the counterparty stays empty, as on Android
            if gained.isEmpty, spent.count == 1, let out = spent.first {
                let to = counterparty(asset: out.key, outgoing: true, changes: data.balanceChanges)
                return .sendPayment(value: assetValue(asset: out.key, value: out.value), to: to ?? "", sentToSelf: false)
            }
            if spent.isEmpty, gained.count == 1, let inn = gained.first {
                let from = counterparty(asset: inn.key, outgoing: false, changes: data.balanceChanges)
                return .receivePayment(value: assetValue(asset: inn.key, value: inn.value), from: from ?? "")
            }
            return .unsupported(type: data.function)
        case let .unknown(rawType):
            return .unsupported(type: rawType)
        }
    }

    // Where the moved asset went (outgoing) or came from (incoming): the first change of that
    // asset touching this account in that direction
    private func counterparty(asset: Asset, outgoing: Bool, changes: [TxOperation.BalanceChange]) -> String? {
        if outgoing {
            return changes.first { $0.asset == asset && $0.from == accountId }?.to
        }
        return changes.first { $0.asset == asset && $0.to == accountId }?.from
    }
}

extension StellarOperationConverter {
    /// All operations of ONE transaction (the adapter groups by hash). The swap is the primary
    /// action when the tx contains one — e.g. a DEX swap whose service-fee payment op rides the
    /// same atomic tx renders as a single "Swapped" row, the fee as a Tx Info fund flow.
    /// Nil for an empty group — `StellarTransactionRecord` indexes `operations[primaryIndex]`
    /// and would trap. The adapter's grouping never produces one, but the contract is explicit
    /// rather than a latent crash for any future caller.
    func transactionRecord(operations: [TxOperation]) -> StellarTransactionRecord? {
        guard !operations.isEmpty else {
            return nil
        }

        let types = operations.map { type(type: $0.type) }
        let primaryIndex = types.firstIndex {
            if case .swap = $0 { return true }
            return false
        } ?? 0

        return StellarTransactionRecord(source: source, operations: operations, baseToken: baseToken, types: types, primaryIndex: primaryIndex, spam: false)
    }
}
