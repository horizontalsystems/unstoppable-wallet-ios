import RxSwift
import RxCocoa
import UniswapKit

class SwapSlippageViewModel {
    private let disposeBag = DisposeBag()

    private let placeholderRelay = BehaviorRelay<String>(value: "0")
    private let valueRelay = BehaviorRelay<String?>(value: nil)
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let cautionTypeRelay = BehaviorRelay<CautionType>(value: .error)

    private let service: SwapTradeOptionsService
    private let decimalParser: IAmountDecimalParser

    public init(service: SwapTradeOptionsService, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser

//        subscribe(disposeBag, service.tradeOptionsObservable) { [weak self] in self?.update(tradeOptions: $0) }
        subscribe(disposeBag, service.errorsObservable) { [weak self] in self?.update(errors: $0) }

    }

    private func onLeftButtonTapped() {
        valueRelay.accept(service.recommendedSlippageBounds.lowerBound.description)
    }

    private func onRightButtonTapped() {
        valueRelay.accept(service.recommendedSlippageBounds.upperBound.description)
    }

    private func update(tradeOptions: TradeOptions?) {
        valueRelay.accept(tradeOptions?.allowedSlippage.description)
    }

    private func update(errors: [Error]) {
        var slippageError: SwapTradeOptionsError?
        for error in errors.compactMap({ $0 as? SwapTradeOptionsError }) {
            if case .invalidSlippage = error {
                slippageError = error
                break
            }
        }
        cautionRelay.accept(slippageError.map { Caution(text: $0.smartDescription, type: .error)})
    }

}

extension SwapSlippageViewModel: IVerifiedInputViewModel {

    var inputFieldButtonItems: [InputFieldButtonItem] {
        let bounds = service.recommendedSlippageBounds
        return [
            InputFieldButtonItem(style: .secondaryDefault, title: "\(bounds.lowerBound.description)%", visible: .onEmpty) { [weak self] in
                self?.onLeftButtonTapped()
            },
            InputFieldButtonItem(style: .secondaryDefault, title: "\(bounds.upperBound.description)%", visible: .onEmpty) { [weak self] in
                self?.onRightButtonTapped()
            }
        ]
    }

    var inputFieldPlaceholder: String? {
        service.defaultSlippage.description
    }

    var inputFieldValueDriver: Driver<String?> {
        valueRelay.asDriver()
    }

    var inputFieldCautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    var cautionTypeDriver: Driver<CautionType> {
        cautionTypeRelay.asDriver()
    }

    func inputFieldDidChange(text: String?) {
        guard let value = decimalParser.parseAnyDecimal(from: text) else {
            return
        }

        service.slippage = value
    }

    func inputFieldIsValid(text: String) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: text) else {
            return false
        }

        return amount.decimalCount <= 2
    }

}
