import Foundation
import RxRealm

class CollectionChangeSet {

    let deleted: [Int]
    let inserted: [Int]
    let updated: [Int]

    init(withRealmChangeset changeset: RealmChangeset) {
        deleted = changeset.deleted
        inserted = changeset.inserted
        updated = changeset.updated
    }

}
