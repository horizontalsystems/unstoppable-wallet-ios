class WCEvmSendHandlerFactory: IWCSendHandlerFactory {
    private let evmBlockchainManager: EvmBlockchainManager
    private let accountManager: AccountManager
    private let responder: WCResponder

    init(evmBlockchainManager: EvmBlockchainManager, accountManager: AccountManager, responder: WCResponder) {
        self.evmBlockchainManager = evmBlockchainManager
        self.accountManager = accountManager
        self.responder = responder
    }

    func handler(request: WCRequest, inner: SendData?) -> ISendHandler? {
        guard let payload = request.payload as? WCEvmTransactionPayload,
              case .evm? = inner,
              let account = accountManager.activeAccount,
              let chainId = Int(payload.chainId.reference),
              let evmKitWrapper = evmBlockchainManager.kitWrapper(chainId: chainId, account: account)
        else {
            return nil
        }

        return WCEvmSendHandler(payload: payload, request: request, evmKitWrapper: evmKitWrapper, responder: responder, accountName: account.name)
    }
}
