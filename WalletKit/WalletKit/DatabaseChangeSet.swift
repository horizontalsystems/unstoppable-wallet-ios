import Foundation
import RxRealm

public struct DatabaseChangeSet<T> {
    public let array: [T]
    public let changeSet: CollectionChangeSet?
}
