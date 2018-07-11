import Foundation

public class Singletons {
    public static let instance = Singletons()

    private var instances = [String: Any]()

    private init() {
    }

    public var walletManager: WalletManager { return getInstance(creator: {
        return WalletManager(localStorage: userDefaultsStorage)
    })}

    var userDefaultsStorage: UserDefaultsStorage { return getInstance(creator: {
        return UserDefaultsStorage()
    })}

    private func getInstance<T>(instanceName: String? = nil, creator: () -> T) -> T {
        let name = instanceName ?? String(describing: T.self)

        if let instance = instances[name] as? T {
            return instance
        }

        let instance = creator()
        instances[name] = instance
        return instance
    }

}
