import Foundation

class WalletConnectRequestHandler {
    var method: String { fatalError("Must be implemented by subclass") }
    var supportedMethods: [String] { [method] }
}
