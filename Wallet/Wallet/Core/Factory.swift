import Foundation
import RxSwift

class Factory {
    static let instance = Factory()

    private var instances = [String: Any]()

    private init() {
    }

    var randomProvider: RandomProvider { return getInstance(creator: {
        return RandomProvider()
    })}

    var coinManager: CoinManager { return getInstance(creator: {
        return CoinManager()
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
