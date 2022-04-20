import Foundation
import RxSwift
import RxRelay
import RxCocoa

class SendFeeSettingsViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendFeeSettingsService
    private let resetButtonActiveRelay = BehaviorRelay<Bool>(value: false)

    init(service: SendFeeSettingsService) {
        self.service = service

        subscribe(disposeBag, service.isInitialPriorityObservable) { [weak self] in self?.sync(isInitialPriority: $0)}
    }

    private func sync(isInitialPriority: Bool) {
        resetButtonActiveRelay.accept(!isInitialPriority)
    }

}

extension SendFeeSettingsViewModel {

    var resetButtonActiveDriver: Driver<Bool> {
        resetButtonActiveRelay.asDriver()
    }

    func reset() {
        service.reset()
    }

}
