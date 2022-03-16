import RxSwift
import RxRelay
import RxCocoa

class SendXTimeLockViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendXTimeLockService
    private let lockTimeRelay = BehaviorRelay<String?>(value: nil)

    init(service: SendXTimeLockService) {
        self.service = service

        subscribe(disposeBag, service.lockTimeObservable) { [weak self] in self?.sync(lockTime: $0) }
    }

    private func sync(lockTime: SendXTimeLockService.Item) {
        lockTimeRelay.accept(lockTime.title)
    }

}

extension SendXTimeLockViewModel {

    var lockTimeDriver: Driver<String?> {
        lockTimeRelay.asDriver()
    }

    var lockTimeViewItems: [AlertViewItem] {
        service.lockTimeList.map { lockTime in
            AlertViewItem(text: lockTime.title, selected: lockTime == service.lockTime)
        }
    }

    func onSelect(_ index: Int) {
        guard index < service.lockTimeList.count else {
            return
        }

        service.lockTime = service.lockTimeList[index]
    }

}
