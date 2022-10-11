import Foundation
import RxSwift
import RxCocoa
import CurrencyKit
import MarketKit

protocol IIntegerAmountInputService {
    var amount: Int { get }
    var balance: Int? { get }

    var amountObservable: Observable<Int> { get }
    var balanceObservable: Observable<Int?> { get }

    func onChange(amount: Int)
}

class IntegerAmountInputViewModel {
    private var queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.integer-amount-input-view-model", qos: .userInitiated)

    private let disposeBag = DisposeBag()

    private let service: IIntegerAmountInputService
    private let isMaxSupported: Bool

    private var amountRelay = BehaviorRelay<String?>(value: nil)
    private var isMaxEnabledRelay = BehaviorRelay<Bool>(value: false)

    let publishAmountRelay = PublishRelay<Decimal>()

    init(service: IIntegerAmountInputService, isMaxSupported: Bool = true) {
        self.service = service
        self.isMaxSupported = isMaxSupported

        subscribe(disposeBag, service.amountObservable) { [weak self] in self?.sync(amount: $0) }
        subscribe(disposeBag, service.balanceObservable) { [weak self] in self?.sync(balance: $0) }
        subscribe(disposeBag, publishAmountRelay.asObservable()) { [weak self] in self?.sync(publishedAmount: $0) }

        sync(amount: service.amount)
        sync(balance: service.balance)
    }

    private func sync(publishedAmount: Decimal) {
        queue.async { [weak self] in

            let amount = Int(truncating: NSDecimalNumber(decimal: publishedAmount))

            self?.amountRelay.accept("\(amount)")
            self?.service.onChange(amount: amount)
        }
    }

    private func sync(amount: Int) {
        queue.async { [weak self] in
            self?.amountRelay.accept("\(amount)")
            self?.service.onChange(amount: amount)
        }
    }

    private func sync(balance: Int?) {
        queue.async { [weak self] in
            self?.updateMaxEnabled()
        }
    }

    private func updateMaxEnabled() {
        isMaxEnabledRelay.accept(isMaxSupported && (service.balance ?? 0) > 0)
    }

}

extension IntegerAmountInputViewModel {

    func isValid(amount: String?) -> Bool {
        guard let string = amount,
            let _ = Int(string) else {
            return false
        }
        return true
    }

    func equalValue(lhs: String?, rhs: String?) -> Bool {
        lhs.map({ Int($0) }) == rhs.map({ Int($0) })
    }

    var amountDriver: Driver<String?> {
        amountRelay.asDriver()
    }

    var isMaxEnabledDriver: Driver<Bool> {
        isMaxEnabledRelay.asDriver()
    }

    func onChange(amount: String?) {
        let amount = Int(amount ?? "") ?? 0

        service.onChange(amount: amount)
    }

    func onTapMax() {
        guard let balance = service.balance else {
            return
        }

        amountRelay.accept("\(balance)")
        service.onChange(amount: balance)
    }

}

extension IntegerAmountInputViewModel: IAmountPublishService {}
