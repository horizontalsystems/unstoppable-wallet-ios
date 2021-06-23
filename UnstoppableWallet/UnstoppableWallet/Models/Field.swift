import RxSwift
import RxRelay

class Field<T: Equatable> {
    private let relay = PublishRelay<T>()

    var value: T {
        didSet {
            if value != oldValue {
                relay.accept(value)
            }
        }
    }

    init(value: T) {
        self.value = value
    }

    var observable: Observable<T> {
        relay.asObservable()
    }

}
