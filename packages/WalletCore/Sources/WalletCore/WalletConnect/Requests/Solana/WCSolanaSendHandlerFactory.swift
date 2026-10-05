class WCSolanaSendHandlerFactory: IWCSendHandlerFactory {
    private let solanaKitManager: SolanaKitManager
    private let accountManager: AccountManager
    private let coinManager: CoinManager
    private let responder: WCResponder

    init(solanaKitManager: SolanaKitManager, accountManager: AccountManager, coinManager: CoinManager, responder: WCResponder) {
        self.solanaKitManager = solanaKitManager
        self.accountManager = accountManager
        self.coinManager = coinManager
        self.responder = responder
    }

    func handler(request: WCRequest, inner _: SendData?) -> ISendHandler? {
        guard let payload = request.payload as? WCSolanaTransactionPayload,
              let account = accountManager.activeAccount,
              let solanaKit = try? solanaKitManager.solanaKit(account: account),
              let signer = try? SolanaKitManager.signer(accountType: account.type),
              let baseToken = try? coinManager.token(query: .init(blockchainType: .solana, tokenType: .native))
        else {
            return nil
        }

        return WCSolanaSendHandler(payload: payload, request: request, baseToken: baseToken, solanaKit: solanaKit, signer: signer, responder: responder, accountName: account.name)
    }
}
