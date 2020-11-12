import RxSwift
import RxCocoa
import UniswapKit

class SwapDeadlineViewModel {
    private let disposeBag = DisposeBag()

    private let placeholderRelay = BehaviorRelay<String>(value: "0")
    private let valueRelay = BehaviorRelay<String?>(value: nil)
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)

    private let service: SwapTradeOptionsService
    private let decimalParser: IAmountDecimalParser

    public init(service: SwapTradeOptionsService, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser

        setInitial()
    }

    private func toString(_ value: Double) -> String {
        Decimal(floatLiteral: floor(value / 60)).description
    }

    private func setInitial() {
        if case let .valid(tradeOptions) = service.state, tradeOptions.ttl != TradeOptions.defaultTtl {
            valueRelay.accept(toString(tradeOptions.ttl))
        }
    }

    private func onLeftButtonTapped() {
        valueRelay.accept(toString(service.recommendedDeadlineBounds.lowerBound))
    }

    private func onRightButtonTapped() {
        valueRelay.accept(toString(service.recommendedDeadlineBounds.upperBound))
    }

}

extension SwapDeadlineViewModel: IVerifiedInputViewModel {

    var inputFieldButtonItems: [InputFieldButtonItem] {
        let bounds = service.recommendedDeadlineBounds
        return [
            InputFieldButtonItem(style: .secondaryDefault, title: "swap.advanced_settings.deadline_minute".localized(toString(bounds.lowerBound)), visible: .onEmpty) { [weak self] in
                self?.onLeftButtonTapped()
            },
            InputFieldButtonItem(style: .secondaryDefault, title: "swap.advanced_settings.deadline_minute".localized(toString(bounds.upperBound)), visible: .onEmpty) { [weak self] in
                self?.onRightButtonTapped()
            }
        ]
    }

    var inputFieldPlaceholder: String? {
        toString(TradeOptions.defaultTtl)
    }

    var inputFieldValueDriver: Driver<String?> {
        valueRelay.asDriver()
    }

    var inputFieldCautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    func inputFieldDidChange(text: String?) {
        guard let value = decimalParser.parseAnyDecimal(from: text) else {
            service.deadline = TradeOptions.defaultTtl
            return
        }

        service.deadline = NSDecimalNumber(decimal: value).doubleValue * 60
    }

    func inputFieldIsValid(text: String) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: text) else {
            return false
        }

        return amount.decimalCount == 0
    }

}
