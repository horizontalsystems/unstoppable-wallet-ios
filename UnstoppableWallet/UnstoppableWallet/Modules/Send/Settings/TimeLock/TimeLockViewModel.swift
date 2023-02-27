import RxSwift
import RxRelay
import RxCocoa
import Foundation

class TimeLockViewModel {
    private let disposeBag = DisposeBag()

    private let service: TimeLockService
    private let valueRelay = BehaviorRelay<String?>(value: nil)
    private let alteredStateRelay = PublishRelay<Void>()

    init(service: TimeLockService) {
        self.service = service

        subscribe(disposeBag, service.lockTimeObservable) { [weak self] in self?.sync(lockTime: $0) }
        sync(lockTime: service.lockTime)
    }

    private func sync(lockTime: TimeLockService.Item) {
        valueRelay.accept(lockTime.title)
    }

}

extension TimeLockViewModel {

    var altered: Bool {
        service.lockTime != .none
    }

    var alteredStateSignal: Signal<Void> {
        alteredStateRelay.asSignal()
    }

    var itemsList: [AlertViewItem] {
        service.lockTimeList.map { item in
            AlertViewItem(text: item.title, selected: service.lockTime == item)
        }
    }

    func onSelect(_ index: Int) {
        service.set(index: index)
        alteredStateRelay.accept(())
    }

    func reset() {
        service.set(index: 0)
        alteredStateRelay.accept(())
    }

}

extension TimeLockViewModel: IDropDownListViewModel {

    var selectedItemDriver: Driver<String?> {
        valueRelay.asDriver()
    }

}
