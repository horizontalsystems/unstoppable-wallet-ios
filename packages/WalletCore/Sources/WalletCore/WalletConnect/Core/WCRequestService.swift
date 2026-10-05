import HsToolKit
import ReownWalletKit

// Single entry for every incoming request (live, pending replay, expiration): parse → verify → branch
class WCRequestService {
    private let parsers: WCParserRegistry
    private let verifiers: WCVerifierRegistry
    private let responder: WCResponder
    private let logger: Logger?

    init(parsers: WCParserRegistry, verifiers: WCVerifierRegistry, responder: WCResponder, logger: Logger? = nil) {
        self.parsers = parsers
        self.verifiers = verifiers
        self.responder = responder
        self.logger = logger
    }

    func process(request: Request, context: VerifyContext?, session: WCSessionInfo) async -> WCRequestResult {
        let payload: WCRequestPayload
        do {
            payload = try parsers.parse(request: request)
        } catch let error as WCParserRegistry.ParsingError {
            return await reject(request: request, reason: .unsupportedMethod, error: error)
        } catch {
            return await reject(request: request, reason: .invalidParams(reason: "\(error)"), error: error)
        }

        let verificationContext = WCVerificationContext(payload: payload, verifyContext: context, accountId: session.accountId, approvedAccounts: session.approvedAccounts)
        let verdict = verifiers.verify(verificationContext)

        let wcnRequest = WCRequest(payload: payload, verdict: verdict, dAppName: session.dAppName, dAppUrl: session.peerUrl, dAppIconUrl: session.peerIconUrl)

        switch payload.kind {
        case .transaction:
            return .transaction(request: wcnRequest, sendData: .walletConnect(inner: payload.makeSendData(), request: wcnRequest))
        case .signMessage:
            return .signMessage(request: wcnRequest)
        case .direct:
            return .direct(request: wcnRequest)
        }
    }

    private func reject(request: Request, reason: WCResponder.RejectReason, error: Error) async -> WCRequestResult {
        logger?.warning("rejecting id=\(request.id.string): \(error)")
        let unparsed = WCRequestPayload(request: request, kind: .direct, from: nil)

        do {
            try await responder.reject(request: unparsed, reason: reason)
        } catch {
            logger?.error("reject failed for id=\(request.id.string): \(error)")
        }

        return .rejected(reason: reason)
    }
}
