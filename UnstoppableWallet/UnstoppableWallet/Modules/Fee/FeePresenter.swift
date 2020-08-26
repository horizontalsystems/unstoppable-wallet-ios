import Foundation
import CurrencyKit
import XRatesKit
import RxSwift
import RxCocoa
import EthereumKit

class FeePresenter {
    private let disposeBag = DisposeBag()

    let service: FeeService

    private var feeRelay = BehaviorRelay<String>(value: "")
    private var feeLoadingRelay = BehaviorRelay<Bool>(value: true)
    private var errorRelay = PublishRelay<Error>()

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

    private func handle(feeState: DataState<(coinValue: CoinValue, currencyValue: CurrencyValue?)>) {
        switch feeState {
        case .success(result: let feeValues):
            if let feeRate = service.gasPrice {
                let fee = feeValue(coinValue: feeValues.coinValue, currencyValue: feeValues.currencyValue, reversed: false)
                feeRelay.accept(fee)
            }

        case .error(error: let error):
            errorRelay.accept(error)

        case .loading:
            feeLoadingRelay.accept(true)
        }
    }

}

extension FeePresenter {

    var priorityTitle: String {
        service.priority.title
    }

    public var fee: Driver<String> {
        feeRelay.asDriver()
    }

    public var feeLoading: Driver<Bool> {
        feeLoadingRelay.asDriver()
    }

    public var error: Signal<String> {
        errorRelay.asSignal().map({ $0.smartDescription })
    }

}
