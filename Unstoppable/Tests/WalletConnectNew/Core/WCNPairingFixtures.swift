import Foundation
import ReownWalletKit
@testable import WalletCore

enum WCNPairingFixtures {
    // proposal exactly as react-app.walletconnect.com sent it during the 2026-09-02 spike (relay-only fields)
    static func proposal() throws -> Session.Proposal {
        let json = """
        {"id":"e8879a02df7049f79a20edf641c79b82a0051ed7e6675b9f2f9eb00f97bdd53f","pairingTopic":"1a30b752133b379b64bf5c246ec279df4d3145666907d3525ded6aeed9d03cd5","requiredNamespaces":{},"optionalNamespaces":{"eip155":{"chains":["eip155:1","eip155:10"],"methods":["eth_sendTransaction","personal_sign"],"events":["accountsChanged","chainChanged"]}},"proposer":{"name":"React App","description":"App to test WalletConnect network","url":"https://react-app.walletconnect.com","icons":["https://avatars.githubusercontent.com/u/37784886"]},"proposal":{"relays":[{"protocol":"irn"}],"proposer":{"publicKey":"e8879a02df7049f79a20edf641c79b82a0051ed7e6675b9f2f9eb00f97bdd53f","metadata":{"name":"React App","description":"App to test WalletConnect network","url":"https://react-app.walletconnect.com","icons":["https://avatars.githubusercontent.com/u/37784886"]}},"requiredNamespaces":{},"optionalNamespaces":{"eip155":{"chains":["eip155:1","eip155:10"],"methods":["eth_sendTransaction","personal_sign"],"events":["accountsChanged","chainChanged"]}},"expiryTimestamp":1788350621}}
        """
        return try JSONDecoder().decode(Session.Proposal.self, from: Data(json.utf8))
    }
}
