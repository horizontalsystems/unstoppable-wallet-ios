import BigInt
import Foundation
import MarketKit
import ThorChainKit

class ThorChainTransactionConverter {
    private let source: TransactionSource
    private let baseToken: Token
    private let coinManager: ICoinManager
    private let ownAddress: String
    private let network: ThorChainKit.Network

    init(source: TransactionSource, baseToken: Token, coinManager: ICoinManager, thorChainKitWrapper: ThorChainKitWrapper) {
        self.source = source
        self.baseToken = baseToken
        self.coinManager = coinManager
        ownAddress = thorChainKitWrapper.thorChainKit.address.raw
        network = thorChainKitWrapper.thorChainKit.network
    }

    private func isOwn(_ address: String) -> Bool {
        address.caseInsensitiveCompare(ownAddress) == .orderedSame
    }

    private func uid(transaction: ThorChainKit.Transaction, asset: String) -> String {
        "\(transaction.transactionId.hash)-\(asset.lowercased())"
    }

    private func appValue(_ transfer: ThorChainKit.CoinTransfer, sign: FloatingPointSign) -> AppValue {
        func value(decimals: Int) -> Decimal {
            Decimal(
                sign: sign,
                exponent: -decimals,
                significand: Decimal(string: transfer.amount.description) ?? 0
            )
        }

        guard let asset = try? network.chain.asset(for: transfer.asset) else {
            let ticker = fallbackTicker(transfer.asset)
            return AppValue(tokenName: ticker, tokenCode: ticker, tokenDecimals: network.decimals, value: value(decimals: network.decimals))
        }

        let denom = network.chain.denom(for: asset)

        guard denom != network.nativeDenom.rawValue else {
            return AppValue(token: baseToken, value: value(decimals: baseToken.decimals))
        }

        if let token = try? coinManager.token(query: TokenQuery(blockchainType: baseToken.blockchainType, tokenType: .thorChainAsset(denom: denom))) {
            return AppValue(token: token, value: value(decimals: token.decimals))
        }

        // A chain asset MarketKit does not know yet still has to carry its ticker:
        // without a value every token filter drops the record.
        let decimals = fallbackDecimals(denom: denom)
        return AppValue(tokenName: asset.ticker, tokenCode: asset.ticker, tokenDecimals: decimals, value: value(decimals: decimals))
    }

    // Bank-denom decimals for assets MarketKit does not list. THOR is uniformly 1e8;
    // Maya is heterogeneous: CACAO 1e10, the MAYA governance token 1e4 (verified against
    // the MAYA.MAYA pool depth on midgard), synths 1e8.
    private func fallbackDecimals(denom: String) -> Int {
        guard network.chain == .maya else { return network.decimals }
        switch denom {
        case "cacao": return 10
        case "maya": return 4
        default: return 8
        }
    }

    private func fallbackTicker(_ midgardAsset: String) -> String {
        let afterChain = midgardAsset.split(separator: ".").last.map(String.init) ?? midgardAsset
        return String(afterChain.prefix { $0 != "-" }).uppercased()
    }
}

extension ThorChainTransactionConverter {
    // Midgard action semantics: `incoming` transfers enter the action (spent by their
    // address), `outgoing` transfers leave it (received by their address). One action
    // can carry the user on BOTH sides with different assets — a swap spends RUNE and
    // delivers TCY in the same action — so every user-side transfer becomes its own
    // record; a single-record conversion would drop the received asset entirely.
    func transactionRecords(from transaction: ThorChainKit.Transaction) -> [ThorChainTransactionRecord] {
        let userSpends = transaction.incoming.filter { isOwn($0.address) }
        let userReceives = transaction.outgoing.filter { isOwn($0.address) }
        let spentAssets = Set(userSpends.map(\.asset))

        var records = [ThorChainTransactionRecord]()

        for transfer in userSpends {
            // the counterparty must be matched by asset: in a swap the first outgoing
            // entry is the user's own receive of the other asset, not the recipient
            let to = transaction.outgoing.first { $0.asset == transfer.asset }?.address

            records.append(
                ThorChainOutgoingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    uid: uid(transaction: transaction, asset: transfer.asset),
                    to: to,
                    value: appValue(transfer, sign: .minus),
                    sentToSelf: userReceives.contains { $0.asset == transfer.asset }
                )
            )
        }

        for transfer in userReceives {
            // a same-asset receive in an action the user also spent from is change or a
            // self-transfer (or a refund) — already represented by the outgoing record,
            // and a second record would collide with its uid
            guard !spentAssets.contains(transfer.asset) else { continue }

            records.append(
                ThorChainIncomingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    uid: uid(transaction: transaction, asset: transfer.asset),
                    from: transaction.incoming.first { $0.asset == transfer.asset }?.address,
                    value: appValue(transfer, sign: .plus)
                )
            )
        }

        return records
    }
}
