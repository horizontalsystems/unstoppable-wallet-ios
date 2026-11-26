/// Supplies the send and pre-send handlers of the plugin's blockchains.
///
/// Handler lists are constants: they are read before `bootstrap`, from an un-bootstrapped instance.
public protocol SendCapability: BlockchainPlugin {
    var sendHandlers: [SendHandler.Type] { get }
    var preSendHandlers: [PreSendHandler.Type] { get }
}
