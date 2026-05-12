import Foundation
import GRDB
import HsToolKit
import MarketKit
import WalletCore

class Core {
    static var instance: Core?

    static func initApp() throws {
        let core = try Core()
        instance = core
    }

    static var shared: Core {
        instance!
    }

    // let marketKit: MarketKit.Kit

    let userDefaultsStorage = UserDefaultsStorage()

    init() throws {
        let databaseDirectoryURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let databaseURL = databaseDirectoryURL.appendingPathComponent("stable.sqlite")
        let dbPool = try DatabasePool(path: databaseURL.path)
    }
}
