import Foundation
import MarketKit
import ThorChainKit

class ThorChainSwapBroadcaster: ISwapBroadcaster {
    private let account: Account

    init(account: Account) {
        self.account = account
    }

    func prepare(_ executable: ISwapExecutable) async throws -> IPrepared {
        guard let executable = executable as? ThorChainExecutable else {
            throw SwapBroadcasterError.dataMismatch
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: executable.token) as? ThorChainAdapter else {
            throw SwapBroadcasterError.dataMismatch
        }

        // The bank denom comes from the token, never from the asset: the two do not
        // round-trip for x/-prefixed tokens.
        let denom: ThorChainKit.Denom
        switch executable.token.type {
        case .native: denom = executable.token.blockchainType == .mayaChain ? .cacao : .rune
        case let .thorChainAsset(rawDenom):
            guard let parsed = try? ThorChainKit.Denom(rawValue: rawDenom) else { throw SwapBroadcasterError.dataMismatch }
            denom = parsed
        default: throw SwapBroadcasterError.dataMismatch
        }

        return ThorChainPrepared(
            wrapper: adapter.thorChainKitWrapper,
            kind: executable.kind,
            denom: denom,
            amount: .exact(executable.token.fractionalMonetaryValue(value: executable.amount)),
            memo: executable.memo
        )
    }

    func submit(_ prepared: IPrepared) async throws -> BroadcastResult {
        guard let prepared = prepared as? ThorChainPrepared else {
            throw SwapBroadcasterError.dataMismatch
        }

        let kit = prepared.wrapper.thorChainKit
        let quote: ThorChainKit.SendQuote
        switch prepared.kind {
        case let .deposit(asset):
            quote = try await kit.depositQuote(asset: asset, denom: prepared.denom, amount: prepared.amount, memo: prepared.memo)
        case let .send(recipient):
            quote = try await kit.quote(to: recipient, amount: prepared.amount, memo: prepared.memo, denom: prepared.denom)
        }

        let submission = try await prepared.wrapper.send(quote: quote)

        switch submission.state {
        case .checkTxAccepted:
            return BroadcastResult(txHash: submission.transactionId.hash, trackingHandle: nil)
        case .unknown:
            throw ThorChainSendHelper.Error.submissionUnknown
        }
    }
}

struct ThorChainPrepared: IPrepared {
    let wrapper: ThorChainKitWrapper
    let kind: ThorChainExecutable.Kind
    let denom: ThorChainKit.Denom
    let amount: ThorChainKit.SendAmount
    let memo: String
}

extension ThorChainSwapBroadcaster: ISwapBroadcasterType {
    static func make(blockchainType: BlockchainType, account: Account) -> ISwapBroadcaster? {
        blockchainType == .thorChain || blockchainType == .mayaChain ? ThorChainSwapBroadcaster(account: account) : nil
    }
}
