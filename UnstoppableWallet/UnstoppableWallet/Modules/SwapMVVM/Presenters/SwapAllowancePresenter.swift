import Foundation
import RxSwift
import RxCocoa

class SwapAllowancePresenter {
    private let disposeBag = DisposeBag()

    private let service: Swap2Service

    private var isHiddenRelay = BehaviorRelay<Bool>(value: false)
    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var allowanceRelay = BehaviorRelay<String?>(value: nil)
    private var insufficientAllowanceRelay = BehaviorRelay<Bool>(value: false)

    init(service: Swap2Service) {
        self.service = service

        subscribeToService()
    }

    private func subscribeToService() {
        subscribe(disposeBag, service.allowance) { [weak self] allowance in self?.handle(allowance: allowance) }
        subscribe(disposeBag, service.validationErrors) { [weak self] errors in self?.handle(errors: errors) }
    }

    private func handle(allowance: DataStatus<CoinValue>?) {
        allowanceRelay.accept(nil)

        guard let allowance = allowance else {
            isHiddenRelay.accept(true)
            return
        }
        isHiddenRelay.accept(false)
        isLoadingRelay.accept(allowance.isLoading)

        if let allowance = allowance.data {
            let amount = ValueFormatter.instance.format(coinValue: allowance)

            allowanceRelay.accept(amount)
            return
        }

        // TODO: handle api error
    }

    private func handle(errors: [Error]) {
        insufficientAllowanceRelay.accept(false)
        errors.forEach { error in
            if case SwapValidationError.insufficientAllowance = error {
                insufficientAllowanceRelay.accept(true)
                return
            }
        }
    }

}

// TODO: handle changes from base service
extension SwapAllowancePresenter {

    var isHidden: Driver<Bool> {
        isHiddenRelay.asDriver()
    }

    var isLoading: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var allowance: Driver<String?> {
        allowanceRelay.asDriver()
    }

    var insufficientAllowance: Driver<Bool> {
        insufficientAllowanceRelay.asDriver()
    }

}
