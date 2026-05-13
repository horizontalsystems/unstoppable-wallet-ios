import Foundation
import GRDB
import HsToolKit
import MarketKit
import WalletCore

class Core {
    private static let keychainService = "io.horizontalsystems.stable"
    private static let dbName = "stable.sqlite"

    static var instance: Core?

    static func initApp() throws {
        let core = try Core()
        instance = core
    }

    static var shared: Core {
        instance!
    }

    let logger: Logger

    let userDefaultsStorage: UserDefaultsStorage
    let keychainStorage: KeychainStorage

    // let marketKit: MarketKit.Kit

    init() throws {
        let databaseDirectoryURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let databaseURL = databaseDirectoryURL.appendingPathComponent(Self.dbName)
        let dbPool = try DatabasePool(path: databaseURL.path)

        logger = Logger(minLogLevel: .error)

        userDefaultsStorage = UserDefaultsStorage()
        keychainStorage = KeychainStorage(service: Self.keychainService, logger: logger)
    }
}
