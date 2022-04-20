import RxSwift
import RxRelay
import RxCocoa
import Hodler

class SendTimeLockViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendTimeLockService
    private let lockTimeRelay = BehaviorRelay<String?>(value: nil)

    init(service: SendTimeLockService) {
        self.service = service

        subscribe(disposeBag, service.lockTimeObservable) { [weak self] in self?.sync(lockTime: $0) }
    }

    private func sync(lockTime: SendTimeLockService.Item) {
        lockTimeRelay.accept(lockTime.title)
    }

}

extension SendTimeLockViewModel {

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

extension HodlerPlugin.LockTimeInterval {

    static func title(lockTimeInterval: HodlerPlugin.LockTimeInterval?) -> String {
        guard let lockTimeInterval = lockTimeInterval else {
            return "send.hodler_locktime_off".localized
        }

        switch lockTimeInterval {
        case .hour: return "send.hodler_locktime_hour".localized
        case .month: return "send.hodler_locktime_month".localized
        case .halfYear: return "send.hodler_locktime_half_year".localized
        case .year: return "send.hodler_locktime_year".localized
        }
    }

}
