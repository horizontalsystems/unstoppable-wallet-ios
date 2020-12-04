import RxSwift
import RxRelay

protocol IToggleAvailableDelegate: AnyObject {
    var toggleAvailable: Bool { get }
    var toggleAvailableObservable: Observable<Bool> { get }
}

class AmountTypeSwitchService {
    private var disposeBag = DisposeBag()

    weak var fromDelegate: IToggleAvailableDelegate? {
        didSet {
            guard let fromDelegate = fromDelegate else {
                return
            }
            subscribe(disposeBag, fromDelegate.toggleAvailableObservable) { [weak self] _ in self?.syncToggleAvailable() }
        }
    }

    weak var toDelegate: IToggleAvailableDelegate? {
        didSet {
            guard let toDelegate = toDelegate else {
                return
            }
            subscribe(disposeBag, toDelegate.toggleAvailableObservable) { [weak self] _ in self?.syncToggleAvailable() }
        }
    }

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

    private func syncToggleAvailable() {
        toggleAvailable = (fromDelegate?.toggleAvailable ?? false) && (toDelegate?.toggleAvailable ?? false)

        if !toggleAvailable && amountType == .currency { // reset input type if it was set to currency
            amountType = .coin
        }
    }

}

extension AmountTypeSwitchService: IToggleAvailableDelegate {

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
