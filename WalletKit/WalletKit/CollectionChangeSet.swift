import Foundation
import RxRealm

public class CollectionChangeSet {

    public let deleted: [Int]
    public let inserted: [Int]
    public let updated: [Int]

    init(withRealmChangeset changeset: RealmChangeset) {
        deleted = changeset.deleted
        inserted = changeset.inserted
        updated = changeset.updated
    }

}
