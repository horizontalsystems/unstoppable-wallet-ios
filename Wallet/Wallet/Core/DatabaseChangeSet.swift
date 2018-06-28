import Foundation
import RxRealm

struct DatabaseChangeSet<T> {
    let array: [T]
    let changeSet: CollectionChangeSet?
}
