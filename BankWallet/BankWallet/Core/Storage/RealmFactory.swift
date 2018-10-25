import RealmSwift

class RealmFactory {
    private let configuration: Realm.Configuration

    init(configuration: Realm.Configuration) {
        self.configuration = configuration
    }

}

extension RealmFactory: IRealmFactory {

    var realm: Realm {
        return try! Realm(configuration: configuration)
    }

}
