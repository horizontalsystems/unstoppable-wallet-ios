import Combine
import Foundation
import GRDB
import ReownWalletKit
@testable import WalletCore

enum WCSessionFixtures {
    static func storage() throws -> WCSessionStorage {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("wcn-session-tests-\(UUID().uuidString).sqlite").path
        return try WCSessionStorage(dbPool: DatabasePool(path: path))
    }

    static func session(topic: String, dAppName: String = "React App", accounts: [String] = ["eip155:1:\(WCTestFixtures.address)", "eip155:10:\(WCTestFixtures.address)"], methods: Set<String> = ["eth_sendTransaction", "personal_sign"]) throws -> Session {
        let redirect = try AppMetadata.Redirect(native: "unstoppable://", universal: nil)
        let peer = AppMetadata(name: dAppName, description: "App to test WalletConnect network", url: "https://react-app.walletconnect.com", icons: [], redirect: redirect)
        let namespace = SessionNamespace(accounts: accounts.compactMap { WalletConnectUtils.Account($0) }, methods: methods, events: ["chainChanged", "accountsChanged"])
        return Session(topic: topic, pairingTopic: "pairing-\(topic)", peer: peer, requiredNamespaces: [:], namespaces: ["eip155": namespace], sessionProperties: nil, scopedProperties: nil, expiryDate: Date().addingTimeInterval(3600))
    }
}

final class WCStubAccountProvider: IWCAccountProvider {
    let activeAccountSubject: CurrentValueSubject<String?, Never>
    let deletedAccountSubject = PassthroughSubject<String, Never>()

    init(activeAccountId: String?) {
        activeAccountSubject = CurrentValueSubject(activeAccountId)
    }

    var activeAccount: WalletCore.Account? {
        activeAccountSubject.value.map { id in
            WalletCore.Account(id: id, level: 0, name: id, type: WCChainSupportFixtures.walletAccount.type, origin: .restored, backedUp: true, fileBackedUp: false)
        }
    }

    var activeAccountIdPublisher: AnyPublisher<String?, Never> { activeAccountSubject.eraseToAnyPublisher() }
    var deletedAccountIdPublisher: AnyPublisher<String, Never> { deletedAccountSubject.eraseToAnyPublisher() }
}

final class WCStubForegroundProvider: IWCForegroundProvider {
    private let subject: CurrentValueSubject<Bool, Never>

    init(isActive: Bool) {
        subject = CurrentValueSubject(isActive)
    }

    var isActive: Bool {
        get { subject.value }
        set { subject.send(newValue) }
    }

    var isActivePublisher: AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
}
