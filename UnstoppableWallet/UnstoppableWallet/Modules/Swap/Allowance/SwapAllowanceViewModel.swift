import Foundation
import RxSwift
import RxCocoa

class SwapAllowanceViewModel {
    private let disposeBag = DisposeBag()

    private let service: SwapService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService

    private(set) var isVisible: Bool = false {
        didSet {
            isVisibleRelay.accept(isVisible)
        }
    }
    private var isVisibleRelay = PublishRelay<Bool>()
    private var allowanceRelay = BehaviorRelay<String?>(value: nil)
    private var isErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: SwapService, allowanceService: SwapAllowanceService, pendingAllowanceService: SwapPendingAllowanceService) {
        self.service = service
        self.allowanceService = allowanceService
        self.pendingAllowanceService = pendingAllowanceService

        syncVisible()

        subscribe(disposeBag, allowanceService.stateObservable) { [weak self] in self?.handle(allowanceState: $0) }
        subscribe(disposeBag, service.errorsObservable) { [weak self] in self?.handle(errors: $0) }
    }

    private func syncVisible(allowanceState: SwapAllowanceService.State? = nil) {
        let allowanceState = allowanceState ?? allowanceService.state

        guard let state = allowanceState else {
            isVisible = false
            return
        }

        guard !pendingAllowanceService.isPending else {
            isVisible = true
            return
        }

        switch state {
        case .notReady: isVisible = true
        default: isVisible = isErrorRelay.value
        }
    }

    private func handle(allowanceState: SwapAllowanceService.State?) {
        syncVisible(allowanceState: allowanceState)

        if let state = allowanceState {
            allowanceRelay.accept(allowance(state: state))
        }
    }

    private func handle(errors: [Error]) {
        let error = errors.first(where: { .insufficientAllowance == $0 as? SwapService.SwapError })
        isErrorRelay.accept(error != nil)

        syncVisible()
    }

    private func allowance(state: SwapAllowanceService.State) -> String? {
        switch state {
        case .loading:
            return "action.loading".localized
        case .notReady:
            return "n/a".localized
        case .ready(let allowance):
            return allowance.formattedString
        }
    }

}

extension SwapAllowanceViewModel {

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
