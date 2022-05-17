import Foundation
import RxSwift
import RxCocoa
import UniswapKit

protocol ISlippageService {
    var slippageChangeObservable: Observable<Void> { get }

    var defaultSlippage: Decimal { get }
    var initialSlippage: Decimal? { get }
    var recommendedSlippages: [Decimal] { get }
    var slippageError: Error? { get }
    var unusualSlippage: Bool { get }

    func set(slippage: Decimal)
}

class SwapSlippageViewModel {
    private let disposeBag = DisposeBag()

    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)

    private let service: ISlippageService
    private let decimalParser: AmountDecimalParser

    public init(service: ISlippageService, decimalParser: AmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser

        service.slippageChangeObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.sync()
                })
                .disposed(by: disposeBag)

        sync()
    }

    private func sync() {
        let caution: Caution?

        if let error = service.slippageError {
            caution = Caution(text: error.smartDescription, type: .error)
        } else if service.unusualSlippage {
            caution = Caution(text: "swap.advanced_settings.warning.unusual_slippage".localized, type: .warning)
        } else {
            caution = nil
        }

        cautionRelay.accept(caution)
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
        service.recommendedSlippages.map { slippage in
            InputShortcut(title: "\(slippage.description)%", value: slippage.description)
        }
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
