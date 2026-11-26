import Combine
import MarketKit
import SwiftUI

extension NearPlugin {
    func networkSettingsItems() -> [NetworkSettingsItem] {
        [
            NetworkSettingsItem(
                blockchainType: .near,
                title: nodeManager.node(network: kitManager.network).name,
                openStatEvent: .openBlockchainSettingsNear,
                destination: { blockchain, isPresented in
                    AnyView(NodeNetworkView(blockchain: blockchain, isPresented: isPresented))
                }
            ),
        ]
    }

    var networkSettingsUpdated: AnyPublisher<Void, Never> {
        nodeManager.nodeUpdatedPublisher
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
