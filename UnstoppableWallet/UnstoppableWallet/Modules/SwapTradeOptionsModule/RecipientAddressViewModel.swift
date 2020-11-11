import RxSwift
import RxCocoa

class RecipientAddressViewModel {
    private let disposeBag = DisposeBag()

    private let valueRelay = BehaviorRelay<String?>(value: nil)
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)

    private let service: SwapTradeOptionsService

    public init(service: SwapTradeOptionsService) {
        self.service = service

        setInitial()
        subscribe(disposeBag, service.errorsObservable) { [weak self] in self?.update(errors: $0) }
    }

    private func setInitial() {
        if case let .valid(tradeOptions) = service.state {
            valueRelay.accept(tradeOptions.recipient?.hex)
        }
    }

    private func update(errors: [Error]) {
        let error = errors.first(where: {
            if case .invalidAddress = $0 as? SwapTradeOptionsService.TradeOptionsError {
                return true
            }
            return false
        })

        cautionRelay.accept(error.map { Caution(text: $0.smartDescription, type: .error) })
    }

}

extension RecipientAddressViewModel: IVerifiedInputViewModel {

    var inputFieldMaximumNumberOfLines: Int {
        2
    }

    var inputFieldCanEdit: Bool {
        false
    }

    var inputFieldValueDriver: Driver<String?> {
        valueRelay.asDriver()
    }

    var inputFieldCautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    func inputFieldDidChange(text: String?) {
        service.recipient = text
    }

    var inputFieldPlaceholder: String? {
        "swap.advanced_settings.recipient.placeholder".localized
    }

}
