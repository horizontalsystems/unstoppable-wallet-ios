import WalletConnectSign

// Persisted copy of what the user approved: CAIP strings only, never the dApp-mutable SDK namespace
struct WCSessionNamespaces: Codable, Equatable {
    struct Namespace: Codable, Equatable {
        let accounts: [String]
        let methods: [String]
        let events: [String]
    }

    let namespaces: [String: Namespace]

    init(namespaces: [String: Namespace]) {
        self.namespaces = namespaces
    }

    init(sessionNamespaces: [String: SessionNamespace]) {
        namespaces = sessionNamespaces.mapValues {
            Namespace(accounts: $0.accounts.map(\.absoluteString), methods: $0.methods.sorted(), events: $0.events.sorted())
        }
    }

    var accounts: [WalletConnectUtils.Account] {
        namespaces.values.flatMap(\.accounts).compactMap { WalletConnectUtils.Account($0) }
    }

    func contains(_ other: WCSessionNamespaces) -> Bool {
        other.namespaces.allSatisfy { key, namespace in
            guard let own = namespaces[key] else { return false }
            return Set(namespace.accounts).isSubset(of: own.accounts) && Set(namespace.methods).isSubset(of: own.methods) && Set(namespace.events).isSubset(of: own.events)
        }
    }
}
