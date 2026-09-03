class WCNEvmSendHandlerFactory: IWCNSendHandlerFactory {
    private let evmBlockchainManager: EvmBlockchainManager
    private let accountManager: AccountManager
    private let responder: WCNResponder

    init(evmBlockchainManager: EvmBlockchainManager, accountManager: AccountManager, responder: WCNResponder) {
        self.evmBlockchainManager = evmBlockchainManager
        self.accountManager = accountManager
        self.responder = responder
    }

    func handler(request: WCNRequest, inner: SendData) -> ISendHandler? {
        guard let parsed = request.parsed as? WCNEvmTransactionParsed,
              case .evm = inner,
              let account = accountManager.activeAccount,
              let chainId = Int(parsed.chainId.reference),
              let evmKitWrapper = evmBlockchainManager.kitWrapper(chainId: chainId, account: account)
        else {
            return nil
        }

        return WCNEvmSendHandler(parsed: parsed, request: request, evmKitWrapper: evmKitWrapper, responder: responder)
    }
}
