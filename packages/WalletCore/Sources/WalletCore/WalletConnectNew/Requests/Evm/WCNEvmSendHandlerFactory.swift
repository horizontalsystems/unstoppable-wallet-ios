class WCNEvmSendHandlerFactory: IWCNSendHandlerFactory {
    private let evmBlockchainManager: EvmBlockchainManager
    private let accountManager: AccountManager
    private let responder: WCNResponder

    init(evmBlockchainManager: EvmBlockchainManager, accountManager: AccountManager, responder: WCNResponder) {
        self.evmBlockchainManager = evmBlockchainManager
        self.accountManager = accountManager
        self.responder = responder
    }

    func handler(request: WCNRequest, inner: SendData?) -> ISendHandler? {
        guard let payload = request.payload as? WCNEvmTransactionPayload,
              case .evm? = inner,
              let account = accountManager.activeAccount,
              let chainId = Int(payload.chainId.reference),
              let evmKitWrapper = evmBlockchainManager.kitWrapper(chainId: chainId, account: account)
        else {
            return nil
        }

        return WCNEvmSendHandler(payload: payload, request: request, evmKitWrapper: evmKitWrapper, responder: responder, accountName: account.name)
    }
}
