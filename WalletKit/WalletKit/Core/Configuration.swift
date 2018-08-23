import Foundation

class Configuration {

    var network: NetworkProtocol
    var hashCheckpointThreshold: Int = 100

    init(network: WalletKit.Network = .mainNet) {
        switch network {
        case .mainNet: self.network = MainNet()
        case .testNet: self.network = TestNet()
        case .regTest: self.network = RegTest()
        }
    }

}
