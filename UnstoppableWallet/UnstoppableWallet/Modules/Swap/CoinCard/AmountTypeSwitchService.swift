import RxSwift
import RxRelay

enum AmountType {
    case coin
    case currency

    static prefix func ! (lhs: Self) -> Self {
        lhs == .coin ? currency : coin
    }

}

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
    var amountType: AmountType {
        didSet {
            amountTypeRelay.accept(amountType)
        }
    }

    private var toggleAvailableRelay = PublishRelay<Bool>()
    var toggleAvailable: Bool = false {
        didSet {
            toggleAvailableRelay.accept(toggleAvailable)
        }
    }

    init(default: AmountType = .coin) {
        amountType = `default`
    }

    private func syncToggleAvailable() {
        let available = (fromDelegate?.toggleAvailable ?? false) && (toDelegate?.toggleAvailable ?? false)
        if toggleAvailable != available {       // disable toggle in viewModel for all views
            toggleAvailable = available
        }

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
