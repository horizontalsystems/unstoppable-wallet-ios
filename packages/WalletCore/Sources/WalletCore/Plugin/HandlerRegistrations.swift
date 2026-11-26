/// The single seam through which the built-in handler lists reach the static factories.
/// Called once on the launch thread from `Core.initApp`.
struct HandlerRegistrations {
    let sendHandlers: [SendHandler.Type]
    let preSendHandlers: [PreSendHandler.Type]
    let nodeNetworkHandlers: [NodeNetworkHandlerProvider.Type]
    let transactionServices: [TransactionService.Type]
    let swapBroadcasters: [ISwapBroadcasterType.Type]
    let restoreSettingsHandlers: [RestoreSettingsHandler.Type]
    let spendStepHandlers: [SpendStepHandler.Type]

    static func builtIn() -> HandlerRegistrations {
        HandlerRegistrations(
            sendHandlers: SendHandlerFactory.unstoppableHandlers,
            preSendHandlers: SendHandlerFactory.unstoppablePreSendHandlers,
            nodeNetworkHandlers: NodeNetworkHandlerFactory.unstoppableHandlers,
            transactionServices: TransactionServiceFactory.unstoppableTransactionServices,
            swapBroadcasters: SwapBroadcasterFactory.unstoppableBroadcasters,
            restoreSettingsHandlers: RestoreSettingsHandlerFactory.unstoppableHandlers,
            spendStepHandlers: SpendStepHandlerFactory.unstoppableHandlers
        )
    }

    func install() {
        sendHandlers.forEach { SendHandlerFactory.register($0) }
        preSendHandlers.forEach { SendHandlerFactory.register($0) }
        nodeNetworkHandlers.forEach { NodeNetworkHandlerFactory.register($0) }
        transactionServices.forEach { TransactionServiceFactory.register($0) }
        SwapBroadcasterFactory.register(swapBroadcasters)
        restoreSettingsHandlers.forEach { RestoreSettingsHandlerFactory.register($0) }
        spendStepHandlers.forEach { SpendStepHandlerFactory.register($0) }
    }
}
