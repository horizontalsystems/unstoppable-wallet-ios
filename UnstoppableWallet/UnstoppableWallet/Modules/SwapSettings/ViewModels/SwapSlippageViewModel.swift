import Foundation
import RxSwift
import RxCocoa
import UniswapKit

protocol ISlippageService {
    var defaultSlippage: Decimal { get }
    var initialSlippage: Decimal? { get }

    var recommendedSlippageBounds: ClosedRange<Decimal> { get }

    var slippageError: Error? { get }
    var slippageErrorObservable: Observable<Error?> { get }

    func set(slippage: Decimal)
}

class SwapSlippageViewModel {
    private let disposeBag = DisposeBag()

    private let valueRelay = BehaviorRelay<String?>(value: nil)
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)

    private let service: ISlippageService
    private let decimalParser: IAmountDecimalParser

    public init(service: ISlippageService, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser

        service.slippageErrorObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.sync()
                })
                .disposed(by: disposeBag)

        sync()
    }

    private func sync() {
        cautionRelay.accept(service.slippageError.map { Caution(text: $0.smartDescription, type: .error)})
    }

}

extension SwapSlippageViewModel {

    var placeholder: String {
        service.defaultSlippage.description
    }

    var initialValue: String? {
        service.initialSlippage?.description
    }

    var shortcuts: [InputShortcut] {
        let bounds = service.recommendedSlippageBounds

        return [
            InputShortcut(title: "\(bounds.lowerBound.description)%", value: bounds.lowerBound.description),
            InputShortcut(title: "\(bounds.upperBound.description)%", value: bounds.upperBound.description),
        ]
    }

    var cautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    func onChange(text: String?) {
        guard let value = decimalParser.parseAnyDecimal(from: text) else {
            service.set(slippage: service.defaultSlippage)
            return
        }

        service.set(slippage: value)
    }

    func isValid(text: String) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: text) else {
            return false
        }

        return amount.decimalCount <= 2
    }

}

extension SwapSettingsModule.SlippageError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .tooLow: return "swap.advanced_settings.error.lower_slippage".localized
        case .tooHigh(let max): return "swap.advanced_settings.error.higher_slippage".localized(max.description)
        default: return nil
        }
    }

}
