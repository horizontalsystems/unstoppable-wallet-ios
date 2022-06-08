import Foundation
import RxSwift
import RxCocoa
import CurrencyKit
import MarketKit

class SendAmountCautionViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendAmountCautionService
    private let switchService: AmountTypeSwitchService
    private let coinService: CoinService

    private let amountCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private(set) var amountCaution: Caution? = nil {
        didSet {
            amountCautionRelay.accept(amountCaution)
        }
    }

    init(service: SendAmountCautionService, switchService: AmountTypeSwitchService, coinService: CoinService) {
        self.service = service
        self.switchService = switchService
        self.coinService = coinService

        subscribe(disposeBag, service.amountCautionObservable) { [weak self] in
            self?.sync(amountCaution: $0)
        }
    }

    private func sync(amountCaution: SendAmountCautionService.Caution?) {
        guard let amountCaution = amountCaution else {
            self.amountCaution = nil
            return
        }

        var amountInfo: AmountInfo? = nil

        switch switchService.amountType {
        case .coin:
            let coinValue = CoinValue(kind: .token(token: coinService.token), value: amountCaution.value)
            amountInfo = .coinValue(coinValue: coinValue)
        case .currency:
            if let rateValue = coinService.rate {
                let currencyValue = CurrencyValue(currency: rateValue.currency, value: amountCaution.value * rateValue.value)
                amountInfo = .currencyValue(currencyValue: currencyValue)
            }
        }

        switch amountCaution {
        case .insufficientBalance:
            self.amountCaution = Caution(text: "send.amount_error.balance".localized, type: .error)
        case .maximumAmountExceeded:
            self.amountCaution = Caution(text: "send.amount_error.maximum_amount".localized(amountInfo?.formattedFull ?? ""), type: .error)
        case .tooFewAmount:
            self.amountCaution = Caution(text: "send.amount_error.minimum_amount".localized(amountInfo?.formattedFull ?? ""), type: .error)
        }
    }

}

extension SendAmountCautionViewModel {

    var amountCautionDriver: Driver<Caution?> {
        amountCautionRelay.asDriver()
    }

}
