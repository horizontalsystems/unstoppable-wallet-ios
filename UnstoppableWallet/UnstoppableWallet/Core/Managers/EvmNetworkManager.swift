import EthereumKit

class EvmNetworkManager {
    private let appConfigProvider: AppConfigProvider

    init(appConfigProvider: AppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    private func defaultHttpSyncSource(networkType: NetworkType) -> SyncSource? {
        switch networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli:
            return Kit.infuraHttpSyncSource(networkType: networkType, projectId: appConfigProvider.infuraCredentials.id, projectSecret: appConfigProvider.infuraCredentials.secret)
        case .bscMainNet:
            return Kit.defaultBscHttpSyncSource()
        }
    }

    private func defaultWebsocketSyncSource(networkType: NetworkType) -> SyncSource? {
        switch networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli:
            return Kit.infuraWebsocketSyncSource(networkType: networkType, projectId: appConfigProvider.infuraCredentials.id, projectSecret: appConfigProvider.infuraCredentials.secret)
        case .bscMainNet:
            return Kit.defaultBscWebsocketSyncSource()
        }
    }

    private func network(name: String, networkType: NetworkType, syncSource: SyncSource?) -> EvmNetwork? {
        guard let syncSource = syncSource else {
            return nil
        }

        return EvmNetwork(name: name, networkType: networkType, syncSource: syncSource)
    }

    private func defaultHttpNetwork(name: String, networkType: NetworkType) -> EvmNetwork? {
        network(name: name, networkType: networkType, syncSource: defaultHttpSyncSource(networkType: networkType))
    }

    private func defaultWebsocketNetwork(name: String, networkType: NetworkType) -> EvmNetwork? {
        network(name: name, networkType: networkType, syncSource: defaultWebsocketSyncSource(networkType: networkType))
    }

}

extension EvmNetworkManager {

    var ethereumNetworks: [EvmNetwork] {
        let networks: [EvmNetwork?] = [
            defaultWebsocketNetwork(name: "MainNet Websocket", networkType: .ethMainNet),
            defaultHttpNetwork(name: "MainNet HTTP", networkType: .ethMainNet),
//            defaultWebsocketNetwork(name: "Ropsten", networkType: .ropsten),
//            defaultWebsocketNetwork(name: "Rinkeby", networkType: .rinkeby),
//            defaultWebsocketNetwork(name: "Kovan", networkType: .kovan),
//            defaultWebsocketNetwork(name: "Goerli", networkType: .goerli)
        ]

        // todo: load custom network from DB

        return networks.compactMap { $0 }
    }

    var binanceSmartChainNetworks: [EvmNetwork] {
        let networks: [EvmNetwork?] = [
            defaultHttpNetwork(name: "MainNet HTTP", networkType: .bscMainNet),
            defaultWebsocketNetwork(name: "MainNet Websocket", networkType: .bscMainNet)
        ]

        // todo: load custom network from DB

        return networks.compactMap { $0 }
    }

}
