class WCNStellarSendHandlerFactory: IWCNSendHandlerFactory {
    private let stellarKitManager: StellarKitManager
    private let accountManager: AccountManager
    private let coinManager: CoinManager
    private let responder: WCNResponder

    init(stellarKitManager: StellarKitManager, accountManager: AccountManager, coinManager: CoinManager, responder: WCNResponder) {
        self.stellarKitManager = stellarKitManager
        self.accountManager = accountManager
        self.coinManager = coinManager
        self.responder = responder
    }

    func handler(request: WCNRequest, inner _: SendData?) -> ISendHandler? {
        guard let payload = request.payload as? WCNStellarTransactionPayload,
              let account = accountManager.activeAccount,
              let stellarKit = try? stellarKitManager.stellarKit(account: account),
              let keyPair = try? StellarKitManager.keyPair(accountType: account.type),
              let baseToken = try? coinManager.token(query: .init(blockchainType: .stellar, tokenType: .native))
        else {
            return nil
        }

        return WCNStellarSendHandler(payload: payload, request: request, baseToken: baseToken, stellarKit: stellarKit, keyPair: keyPair, responder: responder, accountName: account.name)
    }
}
