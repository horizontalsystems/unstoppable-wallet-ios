import Foundation
import RxSwift

protocol Repository {
    associatedtype Entity

    var state: DataStatus<()> { get }

    func get() -> Single<[Entity]>
    func add(_ entity: Entity) -> Single<Bool>
    func delete(_ entity: Entity) -> Single<Bool>
}
