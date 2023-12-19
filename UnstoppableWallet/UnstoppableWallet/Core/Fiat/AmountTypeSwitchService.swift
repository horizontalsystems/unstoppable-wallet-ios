import RxRelay
import RxSwift

class AmountTypeSwitchService {
    private let amountTypeKey = "amount-type-switch-service-amount-type"
    private let userDefaultsStorage: UserDefaultsStorage
    private let useLocalStorage: Bool

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

    init(userDefaultsStorage: UserDefaultsStorage, useLocalStorage: Bool = true) {
        let localStorageValue = userDefaultsStorage.value(for: amountTypeKey).flatMap { AmountType(rawValue: $0) } ?? .coin
        if useLocalStorage {
            amountType = localStorageValue
        } else {
            amountType = .coin
        }
        self.userDefaultsStorage = userDefaultsStorage
        self.useLocalStorage = useLocalStorage
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

        if !toggleAvailable, amountType == .currency { // reset input type if it was set to currency
            amountType = .coin
        } else if toggleAvailable, useLocalStorage,
                  let savedAmountType = userDefaultsStorage.value(for: amountTypeKey).flatMap({ AmountType(rawValue: $0) }),
                  savedAmountType == .currency, amountType == .coin
        {
            amountType = .currency
        }
    }
}

extension AmountTypeSwitchService {
    func toggle() {
        if toggleAvailable {
            amountType = !amountType
            if useLocalStorage {
                userDefaultsStorage.set(value: amountType.rawValue, for: amountTypeKey)
            }
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
    enum AmountType: String {
        case coin
        case currency

        static prefix func ! (lhs: Self) -> Self {
            lhs == .coin ? currency : coin
        }
    }
}
