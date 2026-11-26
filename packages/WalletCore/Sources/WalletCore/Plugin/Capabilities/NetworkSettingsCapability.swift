import Combine
import MarketKit
import SwiftUI

/// A row the plugin adds to the Blockchain settings screen.
struct NetworkSettingsItem {
    let blockchainType: BlockchainType
    /// The current node or source name, shown as the row's subtitle.
    let title: String
    /// Sent with page `.blockchainSettings` when the row is opened.
    let openStatEvent: StatEvent?
    /// The screen the row opens.
    let destination: (Blockchain, Binding<Bool>) -> AnyView
}

/// Supplies the node-network handlers and the Blockchain settings rows of the plugin's blockchains.
protocol NetworkSettingsCapability: BlockchainPlugin {
    /// A constant: read before `bootstrap`, from an un-bootstrapped instance.
    var nodeNetworkHandlers: [NodeNetworkHandlerProvider.Type] { get }
    /// Called on the main thread.
    func networkSettingsItems() -> [NetworkSettingsItem]
    /// May emit on any thread; the consumer hops to main.
    var networkSettingsUpdated: AnyPublisher<Void, Never> { get }
}
