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

    /// The legacy lists with the plugins' handlers, in `plugins` order, inserted at fixed anchors that
    /// reproduce the order the lists had before the chains moved. The anchors are transitional and move as
    /// families migrate; chain handlers claim disjoint inputs, so only the generic providers' positions are
    /// load-bearing.
    static func builtIn(plugins: [BlockchainPlugin] = BuiltInPlugins.all()) -> HandlerRegistrations {
        let send = plugins.compactMap { $0 as? SendCapability }
        let restoreSettings = plugins.compactMap { $0 as? RestoreSettingsCapability }
        let networkSettings = plugins.compactMap { $0 as? NetworkSettingsCapability }
        let swap = plugins.compactMap { $0 as? SwapCapability }

        return HandlerRegistrations(
            sendHandlers: inserting(send.flatMap(\.sendHandlers), into: SendHandlerFactory.unstoppableHandlers, before: { $0 == MoneroSendHandler.self }),
            preSendHandlers: inserting(send.flatMap(\.preSendHandlers), into: SendHandlerFactory.unstoppablePreSendHandlers, before: { $0 == MoneroPreSendHandler.self }),
            nodeNetworkHandlers: NodeNetworkHandlerFactory.unstoppableHandlers + networkSettings.flatMap(\.nodeNetworkHandlers),
            transactionServices: TransactionServiceFactory.unstoppableTransactionServices,
            swapBroadcasters: inserting(swap.flatMap(\.swapBroadcasters), into: SwapBroadcasterFactory.unstoppableBroadcasters, before: { ObjectIdentifier($0) == ObjectIdentifier(MoneroSwapBroadcaster.self) }),
            restoreSettingsHandlers: RestoreSettingsHandlerFactory.unstoppableHandlers + restoreSettings.flatMap(\.restoreSettingsHandlers),
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

    /// `contributions` placed in front of the first element `isAnchor` accepts, or appended when none does.
    private static func inserting<T>(_ contributions: [T], into list: [T], before isAnchor: (T) -> Bool) -> [T] {
        guard let index = list.firstIndex(where: isAnchor) else {
            return list + contributions
        }

        var result = list
        result.insert(contentsOf: contributions, at: index)
        return result
    }
}
