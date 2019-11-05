import Hodler

class LockTimeIntervalPresenter {
    private let router: ILockTimeIntervalRouter
    private var lockTimeInterval: HodlerPlugin.LockTimeInterval?

    weak var view: IAlertViewController?

    init(router: ILockTimeIntervalRouter, lockTimeInterval: HodlerPlugin.LockTimeInterval?) {
        self.router = router
        self.lockTimeInterval = lockTimeInterval
    }

    private func index(of lockTimeInterval: HodlerPlugin.LockTimeInterval?) -> Int {
        guard let lockTimeInterval = lockTimeInterval else {
            return 0
        }

        switch lockTimeInterval {
        case .hour: return 1
        case .month: return 2
        case .halfYear: return 3
        case .year: return 4
        }
    }

    private func lockTimeInterval(from index: Int) -> HodlerPlugin.LockTimeInterval? {
        switch index {
        case 1: return .hour
        case 2: return .month
        case 3: return .halfYear
        case 4: return .year
        default: return nil
        }
    }

}

extension LockTimeIntervalPresenter: IAlertViewDelegate {
    var items: [AlertItem] {
        [
            .header("send.hodler_locktime"),
            .row("\("send.hodler_locktime_off".localized)"),
            .row("\("send.hodler_locktime_hour".localized)"),
            .row("\("send.hodler_locktime_month".localized)"),
            .row("\("send.hodler_locktime_half_year".localized)"),
            .row("\("send.hodler_locktime_year".localized)"),
        ]
    }

    func onDidLoad(alert: IAlertViewController) {
        view?.setSelected(index: index(of: lockTimeInterval))
    }

    func onSelect(alert: IAlertViewController, index: Int) {
        view?.setSelected(index: index)

        self.lockTimeInterval = lockTimeInterval(from: index)
        router.dismiss(with: self.lockTimeInterval)
    }

}
