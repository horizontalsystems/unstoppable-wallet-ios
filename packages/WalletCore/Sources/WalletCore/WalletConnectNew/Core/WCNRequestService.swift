import HsToolKit
import ReownWalletKit

// Single entry for every incoming request (live, pending replay, expiration): parse → verify → branch
class WCNRequestService {
    private let parsers: WCNParserRegistry
    private let verifiers: WCNVerifierRegistry
    private let responder: WCNResponder
    private let logger: Logger?

    init(parsers: WCNParserRegistry, verifiers: WCNVerifierRegistry, responder: WCNResponder, logger: Logger? = nil) {
        self.parsers = parsers
        self.verifiers = verifiers
        self.responder = responder
        self.logger = logger
    }

    func process(request: Request, context: VerifyContext?, session: WCNSessionInfo) async -> WCNRequestResult {
        logger?.debug("request \(request.method) id=\(request.id.string) topic=\(request.topic) chain=\(request.chainId.absoluteString)")

        let payload: WCNRequestPayload
        do {
            payload = try parsers.parse(request: request)
        } catch let error as WCNParserRegistry.ParsingError {
            return await reject(request: request, reason: .unsupportedMethod, error: error)
        } catch {
            return await reject(request: request, reason: .invalidParams(reason: "\(error)"), error: error)
        }

        let verificationContext = WCNVerificationContext(payload: payload, verifyContext: context, accountId: session.accountId, approvedAccounts: session.approvedAccounts)
        let verdict = verifiers.verify(verificationContext)
        logger?.debug("verdict \(verdict) for id=\(request.id.string)")

        let wcnRequest = WCNRequest(payload: payload, verdict: verdict, dAppName: session.dAppName)

        switch payload.kind {
        case .transaction:
            return .transaction(request: wcnRequest, sendData: .walletConnectNew(inner: payload.makeSendData(), request: wcnRequest))
        case .signMessage:
            return .signMessage(request: wcnRequest)
        case .direct:
            return .direct(request: wcnRequest)
        }
    }

    private func reject(request: Request, reason: WCNResponder.RejectReason, error: Error) async -> WCNRequestResult {
        logger?.warning("rejecting id=\(request.id.string): \(error)")
        let unparsed = WCNRequestPayload(request: request, kind: .direct, from: nil)

        do {
            try await responder.reject(request: unparsed, reason: reason)
        } catch {
            logger?.error("reject failed for id=\(request.id.string): \(error)")
        }

        return .rejected(reason: reason)
    }
}
