import Combine
import Foundation
import GRDB
import ReownWalletKit
@testable import WalletCore

enum WCNSessionFixtures {
    static func storage() throws -> WCNSessionStorage {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("wcn-session-tests-\(UUID().uuidString).sqlite").path
        return try WCNSessionStorage(dbPool: DatabasePool(path: path))
    }

    static func session(topic: String, dAppName: String = "React App", accounts: [String] = ["eip155:1:\(WCNTestFixtures.address)", "eip155:10:\(WCNTestFixtures.address)"], methods: Set<String> = ["eth_sendTransaction", "personal_sign"]) throws -> Session {
        let redirect = try AppMetadata.Redirect(native: "unstoppable://", universal: nil)
        let peer = AppMetadata(name: dAppName, description: "App to test WalletConnect network", url: "https://react-app.walletconnect.com", icons: [], redirect: redirect)
        let namespace = SessionNamespace(accounts: accounts.compactMap { WalletConnectUtils.Account($0) }, methods: methods, events: ["chainChanged", "accountsChanged"])
        return Session(topic: topic, pairingTopic: "pairing-\(topic)", peer: peer, requiredNamespaces: [:], namespaces: ["eip155": namespace], sessionProperties: nil, scopedProperties: nil, expiryDate: Date().addingTimeInterval(3600))
    }
}

final class WCNStubAccountProvider: IWCNAccountProvider {
    let activeAccountSubject: CurrentValueSubject<String?, Never>
    let deletedAccountSubject = PassthroughSubject<String, Never>()

    init(activeAccountId: String?) {
        activeAccountSubject = CurrentValueSubject(activeAccountId)
    }

    var activeAccountId: String? { activeAccountSubject.value }
    var activeAccountIdPublisher: AnyPublisher<String?, Never> { activeAccountSubject.eraseToAnyPublisher() }
    var deletedAccountIdPublisher: AnyPublisher<String, Never> { deletedAccountSubject.eraseToAnyPublisher() }
}
