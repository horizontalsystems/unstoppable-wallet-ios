import Foundation
import MarketKit

// Resolves an IPreSendHandler for the FUNDING token: there is no inner SendData until the commit.
public final class CrossPayHandlerProvider: SendHandler {
    override public class func instance(sendData: SendData) -> ISendHandler? {
        guard case let .crossPay(request) = sendData else { return nil }
        guard let service = Core.crossPayService else { return nil }
        guard let account = Core.shared.accountManager.activeAccount else { return nil }
        guard let baseToken = PrivateSendHandlerProvider.baseToken(token: request.tokenIn) else { return nil }

        let wallet = Wallet(token: request.tokenIn, account: account)

        // Placeholder for handler resolution only — the real destination is the deposit address,
        // which does not exist yet.
        guard let preSendHandler = SendHandlerFactory.preSendHandler(
            wallet: wallet,
            address: ResolvedAddress(address: request.recipient, issueTypes: [])
        ) else { return nil }

        return CrossPayHandler(
            request: request,
            baseToken: baseToken,
            preSendHandler: preSendHandler,
            service: service,
            swapHistoryManager: Core.shared.swapHistoryManager,
            accountManager: Core.shared.accountManager
        )
    }
}
