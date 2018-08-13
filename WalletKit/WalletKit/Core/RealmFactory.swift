import Foundation
import RealmSwift

class RealmFactory {
    private let configuration: Realm.Configuration

    init(configuration: Realm.Configuration) {
        self.configuration = configuration
    }

    var realm: Realm {
        return try! Realm(configuration: configuration)
    }

}
