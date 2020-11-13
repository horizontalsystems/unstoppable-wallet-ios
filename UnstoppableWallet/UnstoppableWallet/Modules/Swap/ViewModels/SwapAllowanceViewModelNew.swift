import Foundation
import RxSwift
import RxCocoa

class SwapAllowanceViewModelNew {
    private let disposeBag = DisposeBag()

    private let service: SwapServiceNew
    private let allowanceService: SwapAllowanceService

    private(set) var isVisible: Bool {
        didSet {
            isVisibleRelay.accept(isVisible)
        }
    }
    private var isVisibleRelay = PublishRelay<Bool>()
    private var allowanceRelay = BehaviorRelay<String?>(value: nil)
    private var isErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: SwapServiceNew, allowanceService: SwapAllowanceService) {
        self.service = service
        self.allowanceService = allowanceService

        isVisible = allowanceService.state != nil

        subscribe(disposeBag, allowanceService.stateObservable) { [weak self] in self?.handle(allowanceState: $0) }
        subscribe(disposeBag, service.errorsObservable) { [weak self] in self?.handle(errors: $0) }
    }

    private func handle(allowanceState: SwapAllowanceService.State?) {
        isVisible = allowanceState != nil

        if let state = allowanceState {
            allowanceRelay.accept(allowance(state: state))
        }
    }

    private func handle(errors: [Error]) {
        let error = errors.first(where: { .insufficientAllowance == $0 as? SwapServiceNew.SwapError })
        isErrorRelay.accept(error != nil)
    }

    private func allowance(state: SwapAllowanceService.State) -> String? {
        switch state {
        case .loading:
            return "action.loading".localized
        case .notReady:
            return "n/a".localized
        case .ready(let allowance):
            return "\(allowance)"
        }
    }

}

extension SwapAllowanceViewModelNew {

    var isVisibleSignal: Signal<Bool> {
        isVisibleRelay.asSignal()
    }

    var allowanceDriver: Driver<String?> {
        allowanceRelay.asDriver()
    }

    var isErrorDriver: Driver<Bool> {
        isErrorRelay.asDriver()
    }

}
