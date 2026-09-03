class WCNSolanaSendHandlerFactory: IWCNSendHandlerFactory {
    private let solanaKitManager: SolanaKitManager
    private let accountManager: AccountManager
    private let coinManager: CoinManager
    private let responder: WCNResponder

    init(solanaKitManager: SolanaKitManager, accountManager: AccountManager, coinManager: CoinManager, responder: WCNResponder) {
        self.solanaKitManager = solanaKitManager
        self.accountManager = accountManager
        self.coinManager = coinManager
        self.responder = responder
    }

    func handler(request: WCNRequest, inner _: SendData?) -> ISendHandler? {
        guard let payload = request.payload as? WCNSolanaTransactionPayload,
              let account = accountManager.activeAccount,
              let solanaKit = try? solanaKitManager.solanaKit(account: account),
              let signer = try? SolanaKitManager.signer(accountType: account.type),
              let baseToken = try? coinManager.token(query: .init(blockchainType: .solana, tokenType: .native))
        else {
            return nil
        }

        return WCNSolanaSendHandler(payload: payload, request: request, baseToken: baseToken, solanaKit: solanaKit, signer: signer, responder: responder)
    }
}
