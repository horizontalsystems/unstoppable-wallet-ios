class PriorityPresenter {
    private let router: IPriorityRouter
    private let interactor: IPriorityInteractor

    private var priority: FeeRatePriority

    weak var view: IAlertViewController?

    init(router: IPriorityRouter, interactor: IPriorityInteractor, priority: FeeRatePriority) {
        self.router = router
        self.interactor = interactor
        self.priority = priority
    }

}

extension PriorityPresenter: IAlertViewDelegate {
    var items: [AlertItem] {
        return [
            .header("send.tx_speed"),
            .row("\("send.tx_speed_low".localized) (\(interactor.duration(priority: .low).approximate_hours_or_minutes))"),
            .row("\("send.tx_speed_medium".localized) (\(interactor.duration(priority: .medium).approximate_hours_or_minutes))"),
            .row("\("send.tx_speed_high".localized) (\(interactor.duration(priority: .high).approximate_hours_or_minutes))"),
        ]
    }

    func onDidLoad(alert: IAlertViewController) {
        view?.setSelected(index: priority.rawValue)
    }

    func onSelect(alert: IAlertViewController, index: Int) {
        view?.setSelected(index: index)

        let selectedPriority = FeeRatePriority(rawValue: index) ?? .medium
        router.dismiss(with: selectedPriority)
    }

}
