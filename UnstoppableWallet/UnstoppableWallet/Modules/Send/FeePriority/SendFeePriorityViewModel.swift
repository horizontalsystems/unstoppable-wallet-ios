import RxSwift
import RxRelay
import RxCocoa

class SendFeePriorityViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendFeePriorityService
    private let priorityRelay = BehaviorRelay<String?>(value: nil)

    init(service: SendFeePriorityService) {
        self.service = service

        subscribe(disposeBag, service.priorityObservable) { [weak self] in self?.sync(priority: $0) }
    }

    private func sync(priority: FeeRatePriority) {
        priorityRelay.accept(priority.title)
    }

}

extension SendFeePriorityViewModel {

    var priorityDriver: Driver<String?> {
        priorityRelay.asDriver()
    }

    var priorityItems: [AlertViewItem] {
        service.feeRatePriorityList.map { priority in
            AlertViewItem(text: priority.title, selected: priority.equalTypes(service.priority))
        }
    }

    func onSelect(_ index: Int) {
        guard index < service.feeRatePriorityList.count else {
            return
        }

        service.priority = service.feeRatePriorityList[index]
    }

}
