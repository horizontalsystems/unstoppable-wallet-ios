import Foundation
import RxSwift
import RxCocoa

class SwapInputModuleViewModel {
    private let disposeBag = DisposeBag()
    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private let service: Swap2Service

    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var isEstimatedRelay = BehaviorRelay<Bool>(value: false)
    private var amountRelay = BehaviorRelay<String?>(value: nil)
    private var tokenCodeRelay = BehaviorRelay<String>(value: "swap.token")

    init(service: Swap2Service) {
        self.service = service

        subscribeToService()
    }

    private func subscribeToService() {
        service.coinIn
            .subscribe(onNext: { [weak self] coin in
                self?.tokenCodeRelay.accept(coin.code)
            })
            .disposed(by: disposeBag)

    }

    private func convert(amount: Decimal?) -> String? {
//        coinFormatter.maximumFractionDigits = service.coinIn.value.decimal
        "----"
//        return amount.flatMap { coinFormatter.string(from: $0 as NSNumber) }
    }

    private func convert(amountText: String?) -> Decimal? {
        0 //TODO: make right conversion
    }

}

extension SwapInputModuleViewModel: ISwapInputViewModel {

    func isValid(amount: String?) -> Bool {
        fatalError("isValid(amount:) has not been implemented")
    }

    var description: String {
        "swap.you_pay"
    }

    var isEstimated: Driver<Bool> {
        isEstimatedRelay.asDriver()
    }

    var isLoading: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var amount: Driver<String?> {
        amountRelay.asDriver()
    }

    var tokenCode: Driver<String> {
        tokenCodeRelay.asDriver()
    }

    var tokensForSelection: [Coin] {
        service.tokensForSelection(type: .exactIn)
    }

    func onChange(amount: String?) {
        service.onChange(type: .exactIn, amount: convert(amountText: amount))
    }

    func onSelect(coin: Coin) {
        service.onSelect(type: .exactIn, coin: coin)
    }

}
