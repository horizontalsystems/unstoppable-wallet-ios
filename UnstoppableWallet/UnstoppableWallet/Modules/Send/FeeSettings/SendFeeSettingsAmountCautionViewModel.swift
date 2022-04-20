import Foundation
import RxSwift
import RxCocoa
import CurrencyKit
import MarketKit

class SendFeeSettingsAmountCautionViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendAmountCautionService
    private let feeCoin: PlatformCoin

    private let amountCautionRelay = BehaviorRelay<TitledCaution?>(value: nil)
    private(set) var amountCaution: TitledCaution? = nil {
        didSet {
            amountCautionRelay.accept(amountCaution)
        }
    }

    init(service: SendAmountCautionService, feeCoin: PlatformCoin) {
        self.service = service
        self.feeCoin = feeCoin

        subscribe(disposeBag, service.amountCautionObservable) { [weak self] in
            self?.sync(amountCaution: $0)
        }
    }

    private func sync(amountCaution: SendAmountCautionService.Caution?) {
        guard let amountCaution = amountCaution else {
            self.amountCaution = nil
            return
        }

        switch amountCaution {
        case .insufficientBalance:
            self.amountCaution = TitledCaution(
                    title: "send.fee_settings.amount_error.balance.title".localized,
                    text: "send.fee_settings.amount_error.balance".localized(feeCoin.code),
                    type: .error)
        default: self.amountCaution = nil
        }
    }

}

extension SendFeeSettingsAmountCautionViewModel {

    var amountCautionDriver: Driver<TitledCaution?> {
        amountCautionRelay.asDriver()
    }

}
