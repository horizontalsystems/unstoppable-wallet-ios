import RxSwift
import RxRelay
import RxCocoa


class MemoInputViewModel {
    private let disposeBag = DisposeBag()
    private let service: MemoInputService

    private let isHiddenRelay = BehaviorRelay<Bool>(value: false)
    var isHidden: Bool = false {
        didSet {
            isHiddenRelay.accept(isHidden)
        }
    }

    init(service: MemoInputService) {
        self.service = service

        subscribe(disposeBag, service.isAvailableObservable) { [weak self] in self?.sync(available: $0) }
        sync(available: service.isAvailable)
    }

    private func sync(available: Bool) {
        isHidden = !available
    }

}

extension MemoInputViewModel {

    var isHiddenDriver: Driver<Bool> {
        isHiddenRelay.asDriver()
    }

    func change(text: String?) {
        service.set(text: text)
    }

    func isValid(text: String) -> Bool {
        service.isValid(text: text)
    }

}
