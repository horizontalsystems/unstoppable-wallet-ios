import Foundation
import RealmSwift

class RealmFactory {
    static let shared = RealmFactory()

    private let realmFileName = "WalletKit.realm"

    let configuration: Realm.Configuration

    init() {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        configuration = Realm.Configuration(fileURL: documentsUrl?.appendingPathComponent(realmFileName))
    }

    var realm: Realm {
        return try! Realm(configuration: configuration)
    }

}
