import Foundation
import RxSwift

class Factory {
    static let instance = Factory()

    private var instances = [String: Any]()

    let unspentOutputUpdateSubject = PublishSubject<[UnspentOutput]>()
    let exchangeRateUpdateSubject = PublishSubject<[String: Double]>()

    private init() {
    }

    var stubWalletDataProvider: StubWalletDataProvider { return getInstance(creator: {
        return StubWalletDataProvider()
    })}

    var stubSettingsProvider: StubSettingsProvider { return getInstance(creator: {
        return StubSettingsProvider()
    })}

    var unspentOutputManager: UnspentOutputManager { return getInstance(creator: {
        return UnspentOutputManager(databaseManager: databaseManager, networkManager: networkManager, updateSubject: unspentOutputUpdateSubject)
    })}

    var exchangeRateManager: ExchangeRateManager { return getInstance(creator: {
        return ExchangeRateManager(databaseManager: databaseManager, networkManager: networkManager, updateSubject: exchangeRateUpdateSubject)
    })}

    var userDefaultsStorage: UserDefaultsStorage { return getInstance(creator: {
        return UserDefaultsStorage()
    })}

    var randomProvider: RandomProvider { return getInstance(creator: {
        return RandomProvider()
    })}

    var mnemonicManager: MnemonicManager { return getInstance(creator: {
        return MnemonicManager()
    })}

    var databaseManager: DatabaseManager { return getInstance(creator: {
        return DatabaseManager()
    })}

    var networkManager: NetworkManager { return getInstance(creator: {
        return NetworkManager(apiUrl: "https://testnet.blockchain.info")
    })}

    private func getInstance<T>(creator: () -> T) -> T {
        let className = String(describing: T.self)

        if let instance = instances[className] as? T {
            return instance
        }

        let instance = creator()
        instances[className] = instance
        return instance
    }

}
