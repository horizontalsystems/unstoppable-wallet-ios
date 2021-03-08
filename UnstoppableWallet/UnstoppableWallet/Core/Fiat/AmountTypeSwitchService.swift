import RxSwift
import RxRelay

class AmountTypeSwitchService {
    private var toggleAvailableObservables = [Observable<Bool>]()
    private var disposeBag = DisposeBag()

    private let amountTypeRelay = PublishRelay<AmountType>()
    private(set) var amountType: AmountType {
        didSet {
            amountTypeRelay.accept(amountType)
        }
    }

    private var toggleAvailableRelay = PublishRelay<Bool>()
    private(set) var toggleAvailable: Bool = false {
        didSet {
            if toggleAvailable != oldValue {
                toggleAvailableRelay.accept(toggleAvailable)
            }
        }
    }

    init(default: AmountType = .coin) {
        amountType = `default`
    }

    private func subscribeToObservables() {
        disposeBag = DisposeBag()

        Observable.combineLatest(toggleAvailableObservables)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] array in
                    self?.syncToggleAvailable(array: array)
                })
                .disposed(by: disposeBag)
    }

    private func syncToggleAvailable(array: [Bool]) {
        toggleAvailable = array.allSatisfy { $0 }

        if !toggleAvailable && amountType == .currency { // reset input type if it was set to currency
            amountType = .coin
        }
    }

}

extension AmountTypeSwitchService {

    func toggle() {
        if toggleAvailable {
            amountType = !amountType
        }
    }

    var amountTypeObservable: Observable<AmountType> {
        amountTypeRelay.asObservable()
    }

    var toggleAvailableObservable: Observable<Bool> {
        toggleAvailableRelay.asObservable()
    }

    func add(toggleAllowedObservable: Observable<Bool>) {
        toggleAvailableObservables.append(toggleAllowedObservable)
        subscribeToObservables()
    }

}

extension AmountTypeSwitchService {

    enum AmountType {
        case coin
        case currency

        static prefix func ! (lhs: Self) -> Self {
            lhs == .coin ? currency : coin
        }

    }

}
