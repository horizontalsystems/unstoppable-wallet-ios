import Foundation
import RxCocoa
import RxRelay
import RxSwift

class RbfViewModel {
    private let service: RbfService
    private let alteredStateRelay = PublishRelay<Void>()

    init(service: RbfService) {
        self.service = service
    }
}

extension RbfViewModel {
    var altered: Bool {
        service.selectedValue != service.initialValue
    }

    var enabled: Bool {
        service.selectedValue
    }

    var alteredStateSignal: Signal<Void> {
        alteredStateRelay.asSignal()
    }

    func onToggle() {
        service.toggle()
        alteredStateRelay.accept(())
    }

    func reset() {
        service.reset()
        alteredStateRelay.accept(())
    }
}
