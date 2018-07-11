import Foundation
import RxSwift

class Factory {
    static let instance = Factory()

    private var instances = [String: Any]()

    private init() {
    }

    var stubSettingsProvider: StubSettingsProvider { return getInstance(creator: {
        return StubSettingsProvider()
    })}

    var randomProvider: RandomProvider { return getInstance(creator: {
        return RandomProvider()
    })}

    var testnetNetworkManager: NetworkManager { return getInstance(name: "testnetNetworkManager", creator: {
        return NetworkManager(apiUrl: "https://testnet.blockchain.info")
    })}

    var networkManager: NetworkManager { return getInstance(creator: {
        return NetworkManager(apiUrl: "https://blockchain.info")
    })}

    var coinManager: CoinManager { return getInstance(creator: {
        return CoinManager()
    })}

    var syncManager: SyncManager { return getInstance(creator: {
        return SyncManager()
    })}

    private func getInstance<T>(name: String? = nil, creator: () -> T) -> T {
        let className = name ?? String(describing: T.self)

        if let instance = instances[className] as? T {
            return instance
        }

        let instance = creator()
        instances[className] = instance
        return instance
    }

}
