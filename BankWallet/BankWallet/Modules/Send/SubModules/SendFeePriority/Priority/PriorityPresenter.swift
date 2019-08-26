class PriorityPresenter {
    private let router: IPriorityRouter

    private var priority: FeeRatePriority

    weak var view: IAlertViewController?

    init(router: IPriorityRouter, priority: FeeRatePriority) {
        self.router = router
        self.priority = priority
    }

}

extension PriorityPresenter: IAlertViewDelegate {
    var items: [AlertItem] {
        return [
            .header("send.tx_speed"),
            .row("send.tx_speed_low"),
            .row("send.tx_speed_medium"),
            .row("send.tx_speed_high"),
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
