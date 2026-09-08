class WCStellarSendHandlerFactory: IWCSendHandlerFactory {
    private let stellarKitManager: StellarKitManager
    private let accountManager: AccountManager
    private let coinManager: CoinManager
    private let responder: WCResponder

    init(stellarKitManager: StellarKitManager, accountManager: AccountManager, coinManager: CoinManager, responder: WCResponder) {
        self.stellarKitManager = stellarKitManager
        self.accountManager = accountManager
        self.coinManager = coinManager
        self.responder = responder
    }

    func handler(request: WCRequest, inner _: SendData?) -> ISendHandler? {
        guard let payload = request.payload as? WCStellarTransactionPayload,
              let account = accountManager.activeAccount,
              let stellarKit = try? stellarKitManager.stellarKit(account: account),
              let keyPair = try? StellarKitManager.keyPair(accountType: account.type),
              let baseToken = try? coinManager.token(query: .init(blockchainType: .stellar, tokenType: .native))
        else {
            return nil
        }

        return WCStellarSendHandler(payload: payload, request: request, baseToken: baseToken, stellarKit: stellarKit, keyPair: keyPair, responder: responder, accountName: account.name)
    }
}
