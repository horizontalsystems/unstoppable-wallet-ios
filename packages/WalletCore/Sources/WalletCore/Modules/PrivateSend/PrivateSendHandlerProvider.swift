import Foundation
import MarketKit

// Resolves an IPreSendHandler rather than an inner ISendHandler: there is no inner SendData to
// resolve from until the order is committed. Nesting is structurally impossible, since the case
// carries no inner SendData, so no anti-nesting guard is needed.
public final class PrivateSendHandlerProvider: SendHandler {
    override public class func instance(sendData: SendData) -> ISendHandler? {
        handler(sendData: sendData) { PrivateSendData(order: $0, inner: $1, innerHandler: $2) }
    }
}

public extension PrivateSendHandlerProvider {
    // Shared resolution, exposed so an app that only needs different field rendering can supply its
    // own data builder without copying any of this.
    static func handler(
        sendData: SendData,
        dataBuilder: @escaping (PrivateSendOrder, ISendData, ISendHandler) -> PrivateSendData
    ) -> ISendHandler? {
        guard case let .privateSend(request) = sendData else { return nil }
        guard let service = Core.privateSendService else { return nil }
        guard let account = Core.shared.accountManager.activeAccount else { return nil }
        guard let baseToken = baseToken(token: request.token) else { return nil }

        let wallet = Wallet(token: request.token, account: account)

        // The recipient, not the deposit address, which does not exist yet. That is fine for
        // *resolving* the handler (it keys on the wallet), but it is why the memo-capability gate is
        // re-evaluated against the deposit address after the commit rather than inferred here.
        guard let preSendHandler = SendHandlerFactory.preSendHandler(
            wallet: wallet,
            address: ResolvedAddress(address: request.recipient, issueTypes: [])
        ) else { return nil }

        return PrivateSendHandler(
            request: request,
            baseToken: baseToken,
            preSendHandler: preSendHandler,
            service: service,
            swapHistoryManager: Core.shared.swapHistoryManager,
            accountManager: Core.shared.accountManager,
            dataBuilder: dataBuilder
        )
    }

    // The fee token for the chain: the network fee is quoted in it, and TransactionServiceFactory
    // keys on it, so a `.privateSend` outer case needs no factory change.
    static func baseToken(token: Token) -> Token? {
        switch token.type {
        case .native, .derived, .addressType:
            return token
        case .eip20, .spl, .jetton, .stellar, .zanoAsset, .thorChainAsset:
            return try? Core.shared.marketKit.token(query: TokenQuery(blockchainType: token.blockchainType, tokenType: .native))
        case .unsupported:
            return nil
        }
    }
}
