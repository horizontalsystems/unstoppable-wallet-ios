import Foundation
import RxSwift
import RxCocoa

class NonceViewModel {
    private let disposeBag = DisposeBag()
    private let service: NonceService

    private let alteredStateRelay = PublishRelay<Void>()
    private let valueRelay = BehaviorRelay<Decimal?>(value: 0)
    private let cautionTypeRelay = BehaviorRelay<CautionType?>(value: nil)

    let frozen: Bool

    init(service: NonceService) {
        self.service = service
        frozen = service.frozen

        sync(nonceStatus: service.status)
        subscribe(disposeBag, service.statusObservable) { [weak self] in self?.sync(nonceStatus: $0) }
        subscribe(disposeBag, service.usingRecommendedObservable) { [weak self] in self?.sync(usingRecommended: $0) }
    }

    private func sync(nonceStatus: DataStatus<FallibleData<Int>>) {
        let cautionType: CautionType?
        let nonce: Decimal?

        switch nonceStatus {
        case .loading:
            cautionType = nil
            nonce = nil
        case .failed(_):
            cautionType = .error
            nonce = nil
        case .completed(let nonceData):
            nonce = Decimal(nonceData.data)
            cautionType = nonceData.cautionType
        }

        cautionTypeRelay.accept(cautionType)
        valueRelay.accept(nonce)
    }

    private func sync(usingRecommended: Bool) {
        alteredStateRelay.accept(Void())
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

    var cautionTypeDriver: Driver<CautionType?> {
        cautionTypeRelay.asDriver()
    }

}
