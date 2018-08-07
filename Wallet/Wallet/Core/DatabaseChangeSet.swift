import Foundation

struct DatabaseChangeSet<T> {
    let array: [T]
    let changeSet: CollectionChangeSet?
}
