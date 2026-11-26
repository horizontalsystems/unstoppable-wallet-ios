/// Supplies the node-network handlers of the plugin's blockchains.
///
/// Handler lists are constants: they are read before `bootstrap`, from an un-bootstrapped instance.
protocol NetworkSettingsCapability: BlockchainPlugin {
    var nodeNetworkHandlers: [NodeNetworkHandlerProvider.Type] { get }
}
