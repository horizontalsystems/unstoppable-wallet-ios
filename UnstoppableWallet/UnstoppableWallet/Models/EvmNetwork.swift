import EthereumKit

class EvmNetwork {
    let name: String
    let networkType: NetworkType
    let syncSource: SyncSource

    init(name: String, networkType: NetworkType, syncSource: SyncSource) {
        self.name = name
        self.networkType = networkType
        self.syncSource = syncSource
    }

    var id: String {
        "\(networkType.chainId)|\(syncSource.urls.map({ $0.absoluteString }).joined(separator: ","))"
    }

}
