import Hodler

class SendHodlerLockTimeIntervalPresenter {
    weak var view: IAlertView?

    private let router: ISendHodlerLockTimeIntervalRouter

    private let selectedLockTimeInterval: HodlerPlugin.LockTimeInterval?
    private let intervals: [HodlerPlugin.LockTimeInterval?]

    init(selectedLockTimeInterval: HodlerPlugin.LockTimeInterval?, router: ISendHodlerLockTimeIntervalRouter) {
        self.selectedLockTimeInterval = selectedLockTimeInterval
        self.router = router

        intervals = [nil] + HodlerPlugin.LockTimeInterval.allCases
    }

}

extension SendHodlerLockTimeIntervalPresenter: IAlertViewDelegate {

    func onLoad() {
        let viewItems = intervals.map { interval in
            AlertViewItem(
                    text: HodlerPlugin.LockTimeInterval.title(lockTimeInterval: interval),
                    selected: interval == selectedLockTimeInterval
            )
        }

        view?.set(viewItems: viewItems)
    }

    func onTapViewItem(index: Int) {
        router.notifyAndClose(lockTimeInterval: intervals[index])
    }

}
