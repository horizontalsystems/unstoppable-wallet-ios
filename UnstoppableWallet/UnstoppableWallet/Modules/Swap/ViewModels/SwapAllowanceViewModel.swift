import Foundation
import RxSwift
import RxCocoa

class SwapAllowanceViewModel {
    private let disposeBag = DisposeBag()

    private let service: SwapService

    private var isHiddenRelay = BehaviorRelay<Bool>(value: false)
    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var allowanceRelay = BehaviorRelay<String?>(value: nil)
    private var insufficientAllowanceRelay = BehaviorRelay<Bool>(value: false)

    init(service: SwapService) {
        self.service = service

        subscribeToService()
    }

    private func subscribeToService() {
        subscribe(disposeBag, service.allowanceObservable) { [weak self] allowance in self?.handle(allowance: allowance) }
        subscribe(disposeBag, service.validationErrorsObservable) { [weak self] errors in self?.handle(errors: errors) }
    }

    private func handle(allowance: DataStatus<Decimal>?) {
        allowanceRelay.accept(nil)

        guard let allowance = allowance else {
            isHiddenRelay.accept(true)
            return
        }
        isHiddenRelay.accept(false)
        isLoadingRelay.accept(allowance.isLoading)

        if let coinIn = service.coinIn, let allowance = allowance.data {
            let coinValue = CoinValue(coin: coinIn, value: allowance)
            let amount = ValueFormatter.instance.format(coinValue: coinValue)

            allowanceRelay.accept(amount)
        }

        if allowance.error != nil {
            allowanceRelay.accept("n/a".localized)
        }
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

extension SwapAllowanceViewModel {

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
