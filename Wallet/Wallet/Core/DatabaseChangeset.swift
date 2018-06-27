import Foundation
import RxRealm

struct DatabaseChangeset<T> {
    let array: [T]

    let deleted: [Int]
    let inserted: [Int]
    let updated: [Int]

    init(array: [T], changeset: RealmChangeset?) {
        self.array = array

        deleted = changeset?.deleted ?? []
        inserted = changeset?.inserted ?? []
        updated = changeset?.updated ?? []
    }

}
