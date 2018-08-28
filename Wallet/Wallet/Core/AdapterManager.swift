import Foundation
import RealmSwift
import RxSwift

class AdapterManager {
    static let shared = AdapterManager()

    var adapters = [IAdapter]()

    var subject = PublishSubject<Void>()

    func add(adapter: IAdapter) {
        adapters.append(adapter)
    }

}
