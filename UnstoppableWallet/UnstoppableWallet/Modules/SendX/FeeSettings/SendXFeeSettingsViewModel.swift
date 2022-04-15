import Foundation
import RxSwift
import RxRelay
import RxCocoa

class SendXFeeSettingsViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendXFeeSettingsService
    private let resetButtonActiveRelay = BehaviorRelay<Bool>(value: false)

    init(service: SendXFeeSettingsService) {
        self.service = service

        subscribe(disposeBag, service.isInitialPriorityObservable) { [weak self] in self?.sync(isInitialPriority: $0)}
    }

    private func sync(isInitialPriority: Bool) {
        resetButtonActiveRelay.accept(!isInitialPriority)
    }

}

extension SendXFeeSettingsViewModel {

    var resetButtonActiveDriver: Driver<Bool> {
        resetButtonActiveRelay.asDriver()
    }

    func reset() {
        service.reset()
    }

}
