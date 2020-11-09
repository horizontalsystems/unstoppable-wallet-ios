import RxSwift
import RxCocoa

class RecipientAddressViewModel {
    private let disposeBag = DisposeBag()

    private let valueRelay = BehaviorRelay<String?>(value: nil)
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)

    private let service: SwapTradeOptionsService

    public init(service: SwapTradeOptionsService) {
        self.service = service

        subscribe(disposeBag, service.errorsObservable) { [weak self] in self?.update(errors: $0) }
    }

    private func update(errors: [Error]) {
        var slippageError: SwapTradeOptionsError?
        for error in errors.compactMap({ $0 as? SwapTradeOptionsError }) {
            if case .invalidAddress = error {
                slippageError = error
                break
            }
        }
        cautionRelay.accept(slippageError.map { Caution(text: $0.smartDescription, type: .error)})
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
