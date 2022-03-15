import RxSwift
import RxRelay
import RxCocoa

class SendXFeePriorityViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendXFeePriorityService
    private let priorityRelay = BehaviorRelay<String?>(value: nil)

    init(service: SendXFeePriorityService) {
        self.service = service

        subscribe(disposeBag, service.priorityObservable) { [weak self] in self?.sync(priority: $0) }
    }

    private func sync(priority: FeeRatePriority) {
        priorityRelay.accept(priority.title)
    }

}

extension SendXFeePriorityViewModel {

    var priorityDriver: Driver<String?> {
        priorityRelay.asDriver()
    }

    var priorityItems: [AlertViewItem] {
        service.feeRatePriorityList.map { priority in
            AlertViewItem(text: priority.title, selected: priority == service.priority)
        }
    }

    func onSelect(_ index: Int) {
        guard index < service.feeRatePriorityList.count else {
            return
        }

        service.priority = service.feeRatePriorityList[index]
    }

}
