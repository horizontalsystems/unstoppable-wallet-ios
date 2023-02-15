import Foundation
import RxSwift
import RxCocoa

class NonceViewModel {
    private let disposeBag = DisposeBag()
    private let service: NonceService

    private let alteredStateRelay = PublishRelay<Void>()
    private let valueRelay = BehaviorRelay<Decimal?>(value: 0)
    private let spinnerVisibleRelay = BehaviorRelay<Bool>(value: false)

    let frozen: Bool

    init(service: NonceService) {
        self.service = service
        frozen = service.frozen

        sync(nonceStatus: service.status)
        subscribe(disposeBag, service.statusObservable) { [weak self] in self?.sync(nonceStatus: $0) }
    }

    private func sync(nonceStatus: DataStatus<FallibleData<Int>>) {
        let spinnerVisible: Bool
        let value: Decimal?

        switch nonceStatus {
        case .loading:
            spinnerVisible = true
            value = nil
        case .failed:
            spinnerVisible = false
            value = nil
        case .completed(let fallibleNonce):
            spinnerVisible = false
            value = Decimal(fallibleNonce.data)
        }

        spinnerVisibleRelay.accept(spinnerVisible)
        valueRelay.accept(value)
    }

}

extension NonceViewModel {

    var altered: Bool {
        !service.usingRecommended
    }

    var alteredStateSignal: Signal<Void> {
        alteredStateRelay.asSignal()
    }

    var valueDriver: Driver<Decimal?> {
        valueRelay.asDriver()
    }

    func set(value: Decimal) {
        service.set(nonce: NSDecimalNumber(decimal: value).intValue)
    }

    func reset() {
        service.resetNonce()
    }

}
