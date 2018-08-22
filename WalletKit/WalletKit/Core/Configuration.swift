import Foundation

class Configuration {

    var network: NetworkProtocol
    var hashCheckpointThreshold: Int = 100

    init(testNet: Bool = false) {
        network = testNet ? TestNet() : MainNet()
    }

}
