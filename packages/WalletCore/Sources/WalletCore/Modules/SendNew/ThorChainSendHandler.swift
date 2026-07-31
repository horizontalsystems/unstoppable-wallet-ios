import Foundation
import MarketKit
import ThorChainKit

final class ThorChainSendHandler: SendHandler, ISendHandler {
    let baseToken: Token
    private let amount: ThorChainKit.SendAmount
    private let recipient: ThorChainKit.Address
    private let memo: String?
    private let thorChainKitWrapper: ThorChainKitWrapper

    override class func instance(sendData: SendData) -> ISendHandler? {
        guard case let .thorChain(token, amount, recipient, memo) = sendData,
              let adapter = Core.shared.adapterManager.adapter(for: token) as? ThorChainAdapter
        else { return nil }

        return ThorChainSendHandler(
            baseToken: token,
            amount: amount,
            recipient: recipient,
            memo: memo,
            thorChainKitWrapper: adapter.thorChainKitWrapper
        )
    }

    init(baseToken: Token, amount: ThorChainKit.SendAmount, recipient: ThorChainKit.Address, memo: String?, thorChainKitWrapper: ThorChainKitWrapper) {
        self.baseToken = baseToken
        self.amount = amount
        self.recipient = recipient
        self.memo = memo
        self.thorChainKitWrapper = thorChainKitWrapper
    }

    var expirationDuration: Int? { 10 }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        do {
            let quote = try await thorChainKitWrapper.quote(to: recipient, amount: amount, memo: memo)
            return ThorChainSendData(token: baseToken, quote: quote, transactionError: nil)
        } catch {
            return ThorChainSendData(token: baseToken, quote: nil, transactionError: error)
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
