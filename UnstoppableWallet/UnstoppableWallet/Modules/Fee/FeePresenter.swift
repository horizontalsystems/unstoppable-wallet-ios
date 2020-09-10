import Foundation
import CurrencyKit
import XRatesKit
import RxSwift
import RxCocoa
import EthereumKit

class FeePresenter {
    private let disposeBag = DisposeBag()

    let service: FeeService

    private var feeRelay = PublishRelay<String?>()
    private var feeLoadingRelay = BehaviorRelay<Bool>(value: true)
    private var errorRelay = PublishRelay<Error?>()

    init(service: FeeService) {
        self.service = service

        subscribe(disposeBag, service.feeState) { [weak self] feeState in self?.handle(feeState: feeState) }
    }

    func feeValue(coinValue: CoinValue, currencyValue: CurrencyValue?, reversed: Bool) -> String {
        let coinValue = ValueFormatter.instance.format(coinValue: coinValue)
        let currencyValue = currencyValue.flatMap { ValueFormatter.instance.format(currencyValue: $0) }

        var array = [coinValue, currencyValue].compactMap { $0 }
        if reversed {
            array.reverse()
        }

        return array.joined(separator: " | ")
    }

    private func handle(feeState: DataStatus<(coinValue: CoinValue, currencyValue: CurrencyValue?)>) {
        feeState.handle(loadingRelay: feeLoadingRelay, completedRelay: feeRelay, failedRelay: errorRelay) { coinValue, currencyValue -> String? in
            feeValue(coinValue: coinValue, currencyValue: currencyValue, reversed: false)
        }
    }

}

extension FeePresenter {

    var priorityTitle: String {
        service.priority.title
    }

    public var fee: Signal<String?> {
        feeRelay.asSignal()
    }

    public var feeLoading: Driver<Bool> {
        feeLoadingRelay.asDriver()
    }

    public var error: Signal<String?> {
        errorRelay.asSignal().map({ $0?.convertedError.smartDescription })
    }

}
