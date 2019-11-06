import UIKit
import Hodler

class SendHodlerRouter {
    weak var viewController: UIViewController?
}

extension SendHodlerRouter {

    static func module() -> (UIView, ISendHodlerModule, ISendSubRouter) {
        let router = SendHodlerRouter()
        let presenter = SendHodlerPresenter(router: router)
        let view = SendHodlerView(delegate: presenter)

        presenter.view = view

        return (view, presenter, router)
    }

}

extension SendHodlerRouter: ISendHodlerRouter {

    func openLockTimeIntervals(selected: HodlerPlugin.LockTimeInterval?, onSelect: @escaping (HodlerPlugin.LockTimeInterval?) -> ()) {
        var intervals: [HodlerPlugin.LockTimeInterval?] = [nil]

        HodlerPlugin.LockTimeInterval.allCases.forEach { interval in
            intervals.append(interval)
        }

        let alertController = AlertViewController(
                header: "send.hodler_locktime".localized,
                rows: intervals.map { interval in
                    let title = interval.map { $0.title } ?? "send.hodler_locktime_off".localized
                    return AlertRow(text: title, selected: interval == selected)
                }
        ) { selectedIndex in
            onSelect(intervals[selectedIndex])
        }

        viewController?.present(alertController, animated: true)
    }

}

extension SendHodlerRouter: ISendSubRouter {
}
