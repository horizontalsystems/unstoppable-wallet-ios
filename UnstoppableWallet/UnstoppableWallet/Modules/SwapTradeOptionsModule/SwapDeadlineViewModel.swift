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

//        subscribe(disposeBag, service.tradeOptionsObservable) { [weak self] in self?.update(tradeOptions: $0) }
    }

    private func onLeftButtonTapped() {
        valueRelay.accept(service.recommendedDeadlineBounds.lowerBound.description)
    }

    private func onRightButtonTapped() {
        valueRelay.accept(service.recommendedDeadlineBounds.upperBound.description)
    }

    private func map(_ deadline: TimeInterval) -> String {
        [deadline.description, "swap.advanced_settings.deadline_minute".localized].joined(separator: " ")
    }

    private func update(tradeOptions: TradeOptions?) {
        valueRelay.accept(tradeOptions?.allowedSlippage.description)
    }

}

extension SwapDeadlineViewModel: IVerifiedInputViewModel {

    var inputFieldButtonItems: [InputFieldButtonItem] {
        let bounds = service.recommendedDeadlineBounds
        return [
            InputFieldButtonItem(style: .secondaryDefault, title: map(bounds.lowerBound), visible: .onEmpty) { [weak self] in
                self?.onLeftButtonTapped()
            },
            InputFieldButtonItem(style: .secondaryDefault, title: map(bounds.upperBound), visible: .onEmpty) { [weak self] in
                self?.onRightButtonTapped()
            }
        ]
    }

    var inputFieldPlaceholder: String? {
        service.defaultDeadline.description
    }

    var inputFieldValueDriver: Driver<String?> {
        valueRelay.asDriver()
    }

    var inputFieldCautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    func inputFieldDidChange(text: String?) {
        guard let value = decimalParser.parseAnyDecimal(from: text) else {
            return
        }

        service.deadline = NSDecimalNumber(decimal: value).doubleValue
    }

    func inputFieldIsValid(text: String) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: text) else {
            return false
        }

        return amount.decimalCount == 0
    }

}
