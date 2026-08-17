import Foundation
import MarketKit
import ThorChainKit

final class ThorChainSendHandler: SendHandler, ISendHandler {
    // `token` is what gets sent; `baseToken` is RUNE, which the fee is always charged in.
    private let token: Token
    let baseToken: Token
    private let amount: ThorChainKit.SendAmount
    private let recipient: ThorChainKit.Address
    private let memo: String?
    private let thorChainKitWrapper: ThorChainKitWrapper

    override class func instance(sendData: SendData) -> ISendHandler? {
        guard case let .thorChain(token, amount, recipient, memo) = sendData,
              let adapter = Core.shared.adapterManager.adapter(for: token) as? ThorChainAdapter,
              let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: token.blockchainType, tokenType: .native))
        else { return nil }

        return ThorChainSendHandler(
            token: token,
            baseToken: baseToken,
            amount: amount,
            recipient: recipient,
            memo: memo,
            thorChainKitWrapper: adapter.thorChainKitWrapper
        )
    }

    init(token: Token, baseToken: Token, amount: ThorChainKit.SendAmount, recipient: ThorChainKit.Address, memo: String?, thorChainKitWrapper: ThorChainKitWrapper) {
        self.token = token
        self.baseToken = baseToken
        self.amount = amount
        self.recipient = recipient
        self.memo = memo
        self.thorChainKitWrapper = thorChainKitWrapper
    }

    // Re-quoting costs ten to eleven sequential preflight requests, far more than the
    // single fee estimate other chains repeat. The THORChain fee is a network constant
    // rather than a floating gas price, so there is nothing to gain from doing it often.
    var expirationDuration: Int? {
        60
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        do {
            let denom: ThorChainKit.Denom
            switch token.type {
            case .native: denom = token.blockchainType == .mayaChain ? .cacao : .rune
            // Never fall back to the native coin on a malformed reference — that would send the wrong asset.
            case let .thorChainAsset(rawDenom):
                guard let parsed = try? ThorChainKit.Denom(rawValue: rawDenom) else { throw SendError.invalidData }
                denom = parsed
            default: throw SendError.invalidData
            }
            let quote = try await thorChainKitWrapper.quote(to: recipient, amount: amount, memo: memo, denom: denom)
            return ThorChainSendData(token: token, baseToken: baseToken, quote: quote, transactionError: nil)
        } catch {
            return ThorChainSendData(token: token, baseToken: baseToken, quote: nil, transactionError: error)
        }
    }

    func send(data: ISendData) async throws {
        guard let data = data as? ThorChainSendData,
              let quote = data.quote
        else {
            throw SendError.invalidData
        }

        let submission = try await thorChainKitWrapper.send(quote: quote)

        switch submission.state {
        case .checkTxAccepted:
            return
        case .unknown:
            throw ThorChainSendHelper.Error.submissionUnknown
        }
    }

    enum SendError: Error {
        case invalidData
    }
}
