import Foundation

class ConfigurationManager {
    static let shared = ConfigurationManager()

    var network: NetworkProtocol = TestNet()
    var hashCheckpointThreshold: Int = 100

}
